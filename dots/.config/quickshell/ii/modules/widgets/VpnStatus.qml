pragma Singleton
pragma ComponentBehavior: Bound

// Vpn status and profile list, polled from the `vpn` cli.

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property bool connected: false
    property string vpnName: ""
    property string vpnIp: ""
    property string mode: "" // "full" | "split" | ""
    property int routes: 0

    // [{ name: string, active: bool }, ...] from `vpn list --json`
    property var profiles: []

    // vpn_lock = globe + padlock (protected); public = bare globe (no tunnel).
    readonly property string icon: connected ? "vpn_lock" : "public"

    // Nothing to show without the cli, so the button stays hidden and polling is off
    property bool available: false

    Process {
        running: true
        command: ["bash", "-c", "command -v \"$HOME/.local/bin/vpn\" >/dev/null 2>&1"]
        onExited: (exitCode, exitStatus) => {
            root.available = (exitCode === 0);
        }
    }

    function refresh(): void {
        statusProc.running = true;
        listProc.running = true;
    }

    function connect(name): void {
        Quickshell.execDetached(["bash", "-c", `$HOME/.local/bin/vpn connect ${name}`]);
        followup.restart();
    }

    function disconnect(name): void {
        Quickshell.execDetached(["bash", "-c", `$HOME/.local/bin/vpn disconnect ${name}`]);
        followup.restart();
    }

    function toggle(): void {
        Quickshell.execDetached(["bash", "-c", "$HOME/.local/bin/vpn toggle"]);
        followup.restart();
    }

    Process {
        id: statusProc
        command: ["bash", "-c", "$HOME/.local/bin/vpn status --json"]
        stdout: StdioCollector {
            id: collector
            onStreamFinished: {
                try {
                    const d = JSON.parse(collector.text);
                    root.connected = (d.connected === true);
                    root.vpnName = d.name ?? "";
                    root.vpnIp = d.ip ?? "";
                    root.mode = d.mode ?? "";
                    root.routes = d.routes ?? 0;
                } catch (e) {
                    root.connected = false;
                    root.vpnName = "";
                    root.vpnIp = "";
                    root.mode = "";
                    root.routes = 0;
                }
            }
        }
    }

    Process {
        id: listProc
        command: ["bash", "-c", "$HOME/.local/bin/vpn list --json"]
        stdout: StdioCollector {
            id: listCollector
            onStreamFinished: {
                try {
                    root.profiles = JSON.parse(listCollector.text).profiles ?? [];
                } catch (e) {
                    root.profiles = [];
                }
            }
        }
    }

    // Poll status
    Timer {
        interval: 5000
        running: root.available
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    // Catch-up polls after a toggle, nmcli isn't instant
    Timer {
        id: followup
        interval: 1200
        repeat: true
        property int n: 0
        onRunningChanged: if (running)
            n = 0
        onTriggered: {
            root.refresh();
            if (++n >= 4)
                stop();
        }
    }
}
