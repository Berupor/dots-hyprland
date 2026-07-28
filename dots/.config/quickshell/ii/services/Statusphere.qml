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
    property string selfDeviceId: ""
    readonly property bool available: root.binaryFound && root.registered
    readonly property bool enabled: Config.options.sidebar.statusphere.enable
    readonly property bool shouldRun: root.enabled && root.available

    // Raw member maps from the last parsed line, flat and heterogeneous by design
    property var members: []
    // Each account's current shared photo, if any: { account_id, path, created_at, expires_at }
    property var photos: []
    property bool live: false
    property string lastError: ""

    // One entry per account_id: { id, name, role, offline, devices, primary }
    readonly property var accountsById: {
        const byId = {};
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
            }
            const acc = byId[id];
            if (m._role)
                acc.role = m._role;
            if (m._offline) {
                if (m.account_name)
                    acc.name = m.account_name;
                continue;
            }
            acc.offline = false;
            acc.devices.push(m);
        }
        for (const id in byId) {
            const acc = byId[id];
            const newest = acc.devices.reduce((max, d) => Math.max(max, d.last_seen ?? 0), 0);
            acc.devices.sort((a, b) => root.compareDevices(a, b, newest));
            acc.primary = acc.devices[0] ?? null;
            // Each device publishes its own copy of the account name and they go stale apart,
            // so read it off one fixed device instead of whichever the cli listed last.
            acc.name = root.labelDevice(acc)?.account_name || acc.devices.find(d => d.account_name)?.account_name || acc.name;
        }
        return byId;
    }

    // The cli emits devices in random order, so rank them. Live devices differ by a jittery
    // second of last_seen, so freshness only counts once one falls this far behind the newest.
    readonly property int staleGap: 45

    function deviceRank(device): int {
        if (device.spotify_status === "playing" && !root.stalled(device))
            return 0;
        if (device.spotify_status)
            return 1;
        return 2;
    }

    // A client that keeps saying "playing" while its position sits still lost the Spotify Connect
    // session to another device and never noticed, so watch the position advance per device.
    readonly property int stallTimeout: 8000
    property var progressByDevice: ({})

    function noteProgress(members): void {
        const now = Date.now();
        const next = {};
        for (const m of members) {
            const id = m.device_id;
            if (!id || m.spotify_status !== "playing")
                continue;
            const key = root.trackKey(m);
            const pos = m.spotify_position ?? 0;
            const prev = root.progressByDevice[id];
            next[id] = (prev && prev.key === key && pos <= prev.pos) ? prev : {
                "key": key,
                "pos": pos,
                "at": now
            };
        }
        root.progressByDevice = next;
    }

    function stalled(device): bool {
        const seen = root.progressByDevice[device?.device_id];
        return !!seen && Date.now() - seen.at > root.stallTimeout;
    }

    function compareDevices(a, b, newest): int {
        const behind = d => (newest - (d.last_seen ?? 0) > root.staleGap) ? 1 : 0;
        const own = d => d.device_id === root.selfDeviceId ? 0 : 1;
        return root.deviceRank(a) - root.deviceRank(b) || behind(a) - behind(b) || own(a) - own(b) || (a.device_id ?? "").localeCompare(b.device_id ?? "");
    }

    // One entry per account_id with a live share: { account_id, path, created_at, expires_at }
    readonly property var photosByAccountId: {
        const byId = {};
        for (const p of root.photos) {
            if (p.account_id)
                byId[p.account_id] = p;
        }
        return byId;
    }

    // Ticks so currentPhotoFor's expiry check re-evaluates between stdout lines,
    // not just when the roster/photo list itself changes.
    property real _now: Date.now()

    Timer {
        interval: 30000
        running: root.shouldRun
        repeat: true
        onTriggered: root._now = Date.now()
    }

    function currentPhotoFor(account): var {
        const p = root.photosByAccountId[account?.id];
        if (!p)
            return null;
        const expiresAt = Date.parse(p.expires_at);
        if (isNaN(expiresAt) || root._now >= expiresAt)
            return null;
        return p;
    }

    // Rows look themselves up in accountsById; reassigning this makes the Repeater rebuild
    // every delegate, so only do it when the roster itself changes.
    property var accountIds: []

    onAccountsByIdChanged: {
        const ids = Object.keys(root.accountsById).sort((a, b) => {
            const x = root.accountsById[a];
            const y = root.accountsById[b];
            if (x.offline !== y.offline)
                return x.offline ? 1 : -1;
            return root.nameFor(x).toLowerCase().localeCompare(root.nameFor(y).toLowerCase());
        });
        if (ids.length !== root.accountIds.length || ids.some((id, i) => id !== root.accountIds[i]))
            root.accountIds = ids;
    }

    readonly property int memberCount: root.accountIds.length
    readonly property int onlineCount: Object.values(root.accountsById).filter(a => !a.offline).length

    // A device name is the last resort for the account label, so pick one that stays put when
    // playback hops between devices - primary follows the music, this must not.
    function labelDevice(account): var {
        const devices = account?.devices ?? [];
        return devices.find(d => d.device_id === root.selfDeviceId) ?? devices.slice().sort((a, b) => (a.device_id ?? "").localeCompare(b.device_id ?? ""))[0] ?? null;
    }

    function nameFor(account): string {
        if (!account)
            return "";
        if (account.name)
            return account.name;
        return root.labelDevice(account)?.device_name || account.id.slice(0, 8);
    }

    function initialFor(account): string {
        const name = root.nameFor(account);
        return name ? name.charAt(0).toUpperCase() : "?";
    }

    function trackKey(device): string {
        return device?.spotify_uri || device?.spotify_display || `${device?.spotify_track ?? ""}/${device?.spotify_artist ?? ""}`;
    }

    // Spotify Connect syncs one session across an account's devices, so they report the same
    // track - keep one device per distinct track, playing ones first (devices come sorted).
    function musicDevices(account): var {
        const playing = (account?.devices ?? []).filter(d => d.spotify_status);
        const live = playing.filter(d => !root.stalled(d));
        const seen = new Set();
        return (live.length > 0 ? live : playing).filter(d => {
            const key = root.trackKey(d);
            if (seen.has(key))
                return false;
            seen.add(key);
            return true;
        });
    }

    function statusFor(account): string {
        if (!account || account.offline)
            return "";
        const playing = root.musicDevices(account);
        if (playing.length > 1)
            return Translation.tr("Listening on %1 devices").arg(playing.length);
        const p = account.primary;
        if (p?.active_window)
            return p.active_window;
        if (p?.active_app)
            return p.active_app;
        if (p?.spotify_status)
            return "";
        return Translation.tr("Online");
    }

    function deviceNameFor(device): string {
        return device?.device_name || (device?.device_id ?? "").slice(0, 8);
    }

    function deviceStatusFor(device): string {
        const what = device?.active_window || device?.active_app || Translation.tr("Online");
        const name = root.deviceNameFor(device);
        return name ? `${name} · ${what}` : what;
    }

    function trackFor(device): string {
        if (!device?.spotify_status)
            return "";
        return device.spotify_display || `${device.spotify_track ?? ""} — ${device.spotify_artist ?? ""}`;
    }

    function weatherFor(account): string {
        return account?.primary?.weather ?? "";
    }

    function canSync(device): bool {
        return !!device?.spotify_uri && device.device_id !== root.selfDeviceId;
    }

    // Same mechanism as the TUI's sync action (client/internal/media/media.go): MPRIS OpenUri.
    function syncSpotify(device): void {
        const uri = device?.spotify_uri;
        if (!uri)
            return;
        Quickshell.execDetached(["dbus-send", "--session", "--type=method_call", "--dest=org.mpris.MediaPlayer2.spotify", "/org/mpris/MediaPlayer2", "org.mpris.MediaPlayer2.Player.OpenUri", `string:${uri}`]);
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
            root.noteProgress(data.members ?? []);
            root.members = data.members ?? [];
            root.photos = data.photos ?? [];
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
                    const config = JSON.parse(text);
                    root.selfAccountId = config.account_id ?? "";
                    root.selfDeviceId = config.device_id ?? "";
                } catch (e) {
                    root.selfAccountId = "";
                    root.selfDeviceId = "";
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

    // A heartbeat gap much bigger than its interval means the system was asleep - the feed's
    // connection is likely stale even if it hasn't noticed, so force a reconnect.
    readonly property int heartbeatInterval: 20000
    readonly property int suspendGap: 60000
    property real _lastHeartbeat: 0

    Timer {
        interval: root.heartbeatInterval
        running: root.shouldRun
        repeat: true
        onTriggered: {
            const now = Date.now();
            if (root._lastHeartbeat && now - root._lastHeartbeat > root.suspendGap)
                root.wantRunning = false;
            root._lastHeartbeat = now;
        }
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
            root.photos = [];
            root.wantRunning = false;
            if (root.shouldRun) {
                root.retryDelay = Math.min(root.retryMax, root.retryDelay * 2);
                restartTimer.restart();
            }
        }
    }
}
