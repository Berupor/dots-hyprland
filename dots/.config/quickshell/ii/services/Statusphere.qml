pragma Singleton
pragma ComponentBehavior: Bound

// Room presence, streamed from the `statusphere` cli (github.com/MAX1T1A/statusphere).

import qs.services
import qs.modules.common
import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool binaryFound: false
    property bool registered: false
    property string selfAccountId: ""
    readonly property bool available: root.binaryFound && root.registered
    readonly property bool enabled: Config.options.sidebar.statusphere.enable
    readonly property bool shouldRun: root.enabled && root.available

    // Raw member maps from the last parsed line, flat and heterogeneous by design
    property var members: []
    property bool live: false
    property string lastError: ""

    // One entry per account_id: { id, name, role, offline, devices, primary }
    readonly property var accounts: {
        const byId = {};
        const order = [];
        for (const m of root.members) {
            const id = m.account_id || m.device_id || "";
            if (!id)
                continue;
            if (!byId[id]) {
                byId[id] = {
                    "id": id,
                    "name": "",
                    "role": m._role || "member",
                    "offline": true,
                    "devices": []
                };
                order.push(id);
            }
            const acc = byId[id];
            if (m.account_name)
                acc.name = m.account_name;
            if (m._role)
                acc.role = m._role;
            if (m._offline) {
                continue;
            }
            acc.offline = false;
            acc.devices.push(m);
        }
        const result = order.map(id => {
            const acc = byId[id];
            acc.primary = acc.devices.find(d => d.spotify_status) ?? acc.devices.slice().sort((a, b) => (b.last_seen ?? 0) - (a.last_seen ?? 0))[0] ?? null;
            return acc;
        });
        result.sort((a, b) => {
            if (a.offline !== b.offline)
                return a.offline ? 1 : -1;
            return root.nameFor(a).toLowerCase().localeCompare(root.nameFor(b).toLowerCase());
        });
        return result;
    }

    readonly property int memberCount: root.accounts.length
    readonly property int onlineCount: root.accounts.filter(a => !a.offline).length

    function nameFor(account): string {
        if (!account)
            return "";
        if (account.name)
            return account.name;
        if (account.primary?.device_name)
            return account.primary.device_name;
        return account.id.slice(0, 8);
    }

    function initialFor(account): string {
        const name = root.nameFor(account);
        return name ? name.charAt(0).toUpperCase() : "?";
    }

    function statusFor(account): string {
        if (!account || account.offline)
            return "";
        const p = account.primary;
        if (!p)
            return Translation.tr("Online");
        if (p.active_window)
            return p.active_window;
        if (p.active_app)
            return p.active_app;
        if (p.spotify_status)
            return "";
        return Translation.tr("Online");
    }

    function nowPlayingFor(account): string {
        const p = account?.primary;
        if (!p?.spotify_status)
            return "";
        return p.spotify_display || `${p.spotify_track ?? ""} — ${p.spotify_artist ?? ""}`;
    }

    function weatherFor(account): string {
        return account?.primary?.weather ?? "";
    }

    function canSync(account): bool {
        return !!account?.primary?.spotify_uri && account.id !== root.selfAccountId;
    }

    // Same mechanism as the TUI's sync action (client/internal/media/media.go): MPRIS OpenUri.
    function syncSpotify(account): void {
        const uri = account?.primary?.spotify_uri;
        if (!uri)
            return;
        Quickshell.execDetached(["dbus-send", "--session", "--type=method_call", "--dest=org.mpris.MediaPlayer2.spotify", "/org/mpris/MediaPlayer2", "org.mpris.MediaPlayer2.Player.OpenUri", `string:${uri}`]);
    }

    function iconFor(account): string {
        if (!account || account.offline)
            return "person_off";
        const p = account.primary;
        if (p?.spotify_status === "playing")
            return "music_note";
        if (p?.spotify_status === "paused")
            return "pause";
        if (p?.active_app)
            return "desktop_windows";
        return "circle";
    }

    function detailFor(account): string {
        if (!account)
            return "";
        if (account.offline)
            return Translation.tr("Offline");
        const p = account.primary;
        const parts = [];
        if (p?.active_workspace)
            parts.push(Translation.tr("Workspace %1").arg(p.active_workspace));
        if (p?.last_seen)
            parts.push(NotificationUtils.getFriendlyNotifTimeString(p.last_seen * 1000));
        for (const key of (p?.custom_fields ?? [])) {
            if (key !== "weather" && p[key])
                parts.push(`${key}: ${p[key]}`);
        }
        if (account.devices.length > 1)
            parts.push(Translation.tr("%1 devices").arg(account.devices.length));
        return parts.join(" · ");
    }

    function placeholderText(): string {
        if (!root.binaryFound)
            return Translation.tr("statusphere cli not found in ~/.local/bin");
        if (!root.registered)
            return Translation.tr("No statusphere account registered");
        if (!root.live)
            return root.lastError || Translation.tr("Connecting…");
        return Translation.tr("Nobody else around yet");
    }

    function ingest(line: string): void {
        const text = line.trim();
        if (!text)
            return;
        try {
            const data = JSON.parse(text);
            root.members = data.members ?? [];
            root.live = true;
            root.retryDelay = root.retryMin;
        } catch (e) {
            // Ignore malformed lines, keep the last good roster
        }
    }

    Process {
        running: true
        command: ["bash", "-c", "command -v \"$HOME/.local/bin/statusphere\" >/dev/null 2>&1"]
        onExited: exitCode => root.binaryFound = (exitCode === 0)
    }

    Process {
        running: true
        command: ["bash", "-c", "test -s \"${XDG_CONFIG_HOME:-$HOME/.config}/statusphere/config.json\""]
        onExited: exitCode => root.registered = (exitCode === 0)
    }

    Process {
        running: true
        command: ["bash", "-c", "cat \"${XDG_CONFIG_HOME:-$HOME/.config}/statusphere/config.json\" 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.selfAccountId = JSON.parse(text).account_id ?? "";
                } catch (e) {
                    root.selfAccountId = "";
                }
            }
        }
    }

    readonly property int retryMin: 2000
    readonly property int retryMax: 120000
    property int retryDelay: root.retryMin
    property bool wantRunning: false

    onShouldRunChanged: {
        restartTimer.stop();
        root.retryDelay = root.retryMin;
        root.wantRunning = root.shouldRun;
    }

    Timer {
        id: restartTimer
        interval: root.retryDelay
        onTriggered: root.wantRunning = true
    }

    Process {
        id: feed
        running: root.shouldRun && root.wantRunning
        command: ["bash", "-c", "exec \"$HOME/.local/bin/statusphere\" --ui json"]
        stdout: SplitParser {
            onRead: line => root.ingest(line)
        }
        stderr: SplitParser {
            onRead: line => root.lastError = line
        }
        onExited: (exitCode, exitStatus) => {
            root.live = false;
            root.members = [];
            root.wantRunning = false;
            if (root.shouldRun) {
                root.retryDelay = Math.min(root.retryMax, root.retryDelay * 2);
                restartTimer.restart();
            }
        }
    }
}
