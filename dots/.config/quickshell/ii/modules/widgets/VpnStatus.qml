pragma Singleton
pragma ComponentBehavior: Bound

// Vpn status: OpenVPN/WireGuard profiles via NetworkManager, Tailscale exit node as an
// optional extra layer on top. Tailscale absent just means no tailscale rows - nmcli
// side works standalone.

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property bool nmAvailable: false
    property bool tsAvailable: false
    // nmcli is the hard requirement, tailscale is a bonus that quietly no-ops without it
    readonly property bool available: root.nmAvailable

    property string nmActiveName: ""
    readonly property bool nmConnected: root.nmActiveName !== ""
    property string nmIp: ""
    property string nmMode: "" // "full" | "split" | ""
    property int nmRoutes: 0
    property var nmProfiles: [] // [{ name, active, kind: "nm" }, ...]

    property bool tsExitActive: false
    property string tsExitName: ""
    property string tsExitIp: ""
    property var tsProfiles: [] // [{ name, active, kind: "tailscale" }, ...]

    readonly property bool connected: root.nmConnected || root.tsExitActive
    readonly property string vpnName: root.nmConnected ? root.nmActiveName : (root.tsExitActive ? root.tsExitName : "")
    readonly property string vpnIp: root.nmConnected ? root.nmIp : (root.tsExitActive ? root.tsExitIp : "")
    readonly property string mode: root.nmConnected ? root.nmMode : (root.tsExitActive ? "full" : "")
    readonly property int routes: root.nmConnected ? root.nmRoutes : 0
    readonly property var profiles: root.nmProfiles.concat(root.tsAvailable ? root.tsProfiles : [])

    // vpn_lock = globe + padlock (protected); public = bare globe (no tunnel).
    readonly property string icon: root.connected ? "vpn_lock" : "public"

    Process {
        running: true
        command: ["bash", "-c", "command -v nmcli >/dev/null 2>&1"]
        onExited: (exitCode, exitStatus) => root.nmAvailable = (exitCode === 0)
    }

    Process {
        running: true
        command: ["bash", "-c", "command -v tailscale >/dev/null 2>&1"]
        onExited: (exitCode, exitStatus) => root.tsAvailable = (exitCode === 0)
    }

    function refresh(): void {
        const ovpnDir = WidgetCatalog.option("vpn", "ovpnDir") ?? "";
        if (ovpnDir !== "") {
            nmImportProc.command = ["bash", "-c", `
                dir="\${0/#\\~/$HOME}"
                [ -d "$dir" ] || exit 0
                shopt -s nullglob
                for f in "$dir"/*.ovpn; do
                    name=$(basename "$f" .ovpn)
                    nmcli -t -f NAME connection show | grep -qxF "$name" || nmcli connection import type openvpn file "$f" >/dev/null 2>&1
                done
            `, ovpnDir];
            nmImportProc.running = true;
        }
        nmActiveProc.running = true;
        nmListProc.running = true;
        if (root.tsAvailable)
            tsStatusProc.running = true;
    }

    function connect(name): void {
        const profile = root.profiles.find(p => p.name === name);
        if (!profile)
            return;
        if (profile.kind === "tailscale")
            Quickshell.execDetached(["tailscale", "set", `--exit-node=${name}`]);
        else
            Quickshell.execDetached(["nmcli", "connection", "up", "id", name]);
        followup.restart();
    }

    function disconnect(name): void {
        const profile = root.profiles.find(p => p.name === name);
        if (!profile)
            return;
        if (profile.kind === "tailscale")
            Quickshell.execDetached(["tailscale", "set", "--exit-node="]);
        else
            Quickshell.execDetached(["nmcli", "connection", "down", "id", name]);
        followup.restart();
    }

    // Auto-import: any .ovpn dropped in the configured folder becomes an nm profile,
    // named after nmcli's own convention (filename minus extension)
    Process {
        id: nmImportProc
    }

    // Which NM vpn/wireguard connection (if any) is active right now
    Process {
        id: nmActiveProc
        command: ["nmcli", "-t", "-f", "NAME,TYPE", "connection", "show", "--active"]
        stdout: StdioCollector {
            id: nmActiveCollector
            onStreamFinished: {
                const active = nmActiveCollector.text.trim().split("\n")
                    .filter(line => line !== "")
                    .map(line => line.split(":"))
                    .find(([, type]) => type === "vpn" || type === "wireguard");
                root.nmActiveName = active ? active[0] : "";
                if (root.nmActiveName) {
                    nmDetailsProc.command = ["nmcli", "-g", "IP4.ADDRESS,IP4.ROUTE", "connection", "show", "id", root.nmActiveName];
                    nmDetailsProc.running = true;
                } else {
                    root.nmIp = "";
                    root.nmMode = "";
                    root.nmRoutes = 0;
                }
            }
        }
    }

    // Address and route table of the active connection, mode/routes derived from routes.
    // Multi-values on a line come "|"-separated; each route reads "dst = <cidr>, nh = …, mt = …"
    Process {
        id: nmDetailsProc
        stdout: StdioCollector {
            id: nmDetailsCollector
            onStreamFinished: {
                const lines = nmDetailsCollector.text.trim().split("\n");
                const addresses = (lines[0] ?? "").split("|").map(s => s.trim()).filter(s => s !== "");
                const routeList = (lines[1] ?? "").split("|").map(s => s.trim()).filter(s => s !== "");
                root.nmIp = (addresses[0] ?? "").split("/")[0] ?? "";
                root.nmRoutes = routeList.length;
                root.nmMode = routeList.some(r => r.match(/dst\s*=\s*0\.0\.0\.0\/0/)) ? "full" : (routeList.length > 0 ? "split" : "");
            }
        }
    }

    // All vpn/wireguard connections, active or not, for the profile list
    Process {
        id: nmListProc
        command: ["nmcli", "-t", "-f", "NAME,TYPE", "connection", "show"]
        stdout: StdioCollector {
            id: nmListCollector
            onStreamFinished: {
                root.nmProfiles = nmListCollector.text.trim().split("\n")
                    .filter(line => line !== "")
                    .map(line => line.split(":"))
                    .filter(([, type]) => type === "vpn" || type === "wireguard")
                    .map(([name]) => ({
                        name,
                        active: name === root.nmActiveName,
                        kind: "nm"
                    }));
            }
        }
    }

    // Tailscale exit node candidates: peers that advertise --advertise-exit-node
    Process {
        id: tsStatusProc
        command: ["tailscale", "status", "--json"]
        stdout: StdioCollector {
            id: tsCollector
            onStreamFinished: {
                try {
                    const status = JSON.parse(tsCollector.text);
                    const peers = Object.values(status.Peer ?? {});
                    const candidates = peers.filter(p => p.ExitNodeOption === true);
                    const active = candidates.find(p => p.ExitNode === true);
                    root.tsExitActive = !!active;
                    root.tsExitName = active ? (active.HostName || active.DNSName || "") : "";
                    root.tsExitIp = active ? (active.TailscaleIPs?.[0] ?? "") : "";
                    root.tsProfiles = candidates.map(p => ({
                        name: p.HostName || p.DNSName || "",
                        active: p.ExitNode === true,
                        kind: "tailscale"
                    }));
                } catch (e) {
                    root.tsExitActive = false;
                    root.tsExitName = "";
                    root.tsExitIp = "";
                    root.tsProfiles = [];
                }
            }
        }
    }

    // Poll status
    Timer {
        interval: 5000
        running: root.available && WidgetCatalog.isEnabled("vpn")
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    // Catch-up polls after connect/disconnect, neither nmcli nor tailscale are instant
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
