pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Gpu usage, vram and temperature from sysfs (amdgpu, or any driver exposing gpu_busy_percent).
 */
Singleton {
    id: root

    // Discovered once: card*/hwmon* indices aren't stable across boots
    property string devPath: ""
    property string tempJunctionPath: ""
    property string tempEdgePath: ""

    readonly property bool available: root.devPath.length > 0

    property real usage: 0 // 0..1
    property real vramTotal: 0 // bytes
    property real vramUsed: 0
    readonly property real vramUsedPercentage: root.vramTotal > 0 ? Math.min(1, root.vramUsed / root.vramTotal) : 0
    // -1 = not exposed by this card
    property real tempJunction: -1 // °C, hotspot, the one that hits the limit
    property real tempEdge: -1 // °C, for cards without a junction sensor

    readonly property real temp: root.tempJunction >= 0 ? root.tempJunction : root.tempEdge

    // Plain QML string, so bash $ isn't expanded here
    readonly property string discoverScript: "for c in /sys/class/drm/card*/device; do [ -r \"$c/gpu_busy_percent\" ] || continue; echo \"dev=$c\"; [ -r \"$c/mem_info_vram_total\" ] && echo \"vramtotal=$(cat \"$c/mem_info_vram_total\")\"; for h in \"$c\"/hwmon/hwmon*; do [ -d \"$h\" ] || continue; for t in \"$h\"/temp*_label; do [ -r \"$t\" ] || continue; lbl=$(cat \"$t\"); inp=\"${t%_label}_input\"; [ -r \"$inp\" ] && echo \"temp_$lbl=$inp\"; done; break; done; break; done"

    // text() gives "" on an unloaded FileView, tell that apart from a real zero
    function readNumber(view, fallback: real): real {
        const text = view.text();
        if (!text || text.length === 0)
            return fallback;
        const value = Number(text.trim());
        return isNaN(value) ? fallback : value;
    }

    function refresh(): void {
        if (!root.available)
            return;

        fileBusy.reload();
        fileVramUsed.reload();
        fileTempJunction.reload();
        fileTempEdge.reload();

        root.usage = Math.min(1, Math.max(0, root.readNumber(fileBusy, 0) / 100));
        root.vramUsed = root.readNumber(fileVramUsed, 0);
        root.tempJunction = root.tempJunctionPath.length > 0 ? root.readNumber(fileTempJunction, -1000) / 1000 : -1;
        root.tempEdge = root.tempEdgePath.length > 0 ? root.readNumber(fileTempEdge, -1000) / 1000 : -1;
    }

    Process {
        id: discoverProc
        command: ["bash", "-c", root.discoverScript]
        running: true
        stdout: StdioCollector {
            id: discoverCollector
            onStreamFinished: {
                const lines = discoverCollector.text.trim().split("\n");
                for (const line of lines) {
                    const sep = line.indexOf("=");
                    if (sep <= 0)
                        continue;
                    const key = line.slice(0, sep);
                    const value = line.slice(sep + 1);
                    if (key === "dev")
                        root.devPath = value;
                    else if (key === "vramtotal")
                        root.vramTotal = Number(value);
                    else if (key === "temp_junction")
                        root.tempJunctionPath = value;
                    else if (key === "temp_edge")
                        root.tempEdgePath = value;
                }
                if (root.available)
                    root.refresh();
            }
        }
    }

    Timer {
        interval: Config.options?.resources?.updateInterval ?? 3000
        running: root.available
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    FileView {
        id: fileBusy
        path: root.devPath.length > 0 ? `${root.devPath}/gpu_busy_percent` : ""
    }
    FileView {
        id: fileVramUsed
        path: root.devPath.length > 0 ? `${root.devPath}/mem_info_vram_used` : ""
    }
    FileView {
        id: fileTempJunction
        path: root.tempJunctionPath
    }
    FileView {
        id: fileTempEdge
        path: root.tempEdgePath
    }
}
