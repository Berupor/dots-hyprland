pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Cpu iowait and temperature. Busy comes from ResourceUsage.cpuUsage instead,
 * so the bar and the popup show the same number.
 */
Singleton {
    id: root

    property real iowait: 0 // 0..1, share of time spent waiting on I/O
    property real temp: -1 // °C, -1 = no sensor

    property string tempPath: ""
    property var previousStats

    // Discovered once: hwmon indices aren't stable, and we want the most meaningful sensor (Tdie/Package)
    readonly property string discoverScript: "best=\"\"; bs=0; for h in /sys/class/hwmon/hwmon*; do n=$(cat \"$h/name\" 2>/dev/null) || continue; case \"$n\" in k10temp|zenpower|coretemp) ;; *) continue ;; esac; for t in \"$h\"/temp*_input; do [ -r \"$t\" ] || continue; l=\"\"; [ -r \"${t%_input}_label\" ] && l=$(cat \"${t%_input}_label\"); case \"$l\" in Tdie) s=5 ;; Package*) s=5 ;; Tccd1) s=4 ;; Tctl) s=3 ;; *) s=1 ;; esac; if [ \"$s\" -gt \"$bs\" ]; then bs=$s; best=\"$t\"; fi; done; done; [ -n \"$best\" ] && echo \"temp=$best\""

    function refresh(): void {
        fileStat.reload();
        if (root.tempPath.length > 0)
            fileTemp.reload();

        // Same /proc/stat fields as upstream, but for the I/O wait share
        const cpuLine = fileStat.text().match(/^cpu\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/);
        if (cpuLine) {
            const stats = cpuLine.slice(1).map(Number);
            const total = stats.reduce((a, b) => a + b, 0);
            const iowait = stats[4];
            if (root.previousStats) {
                const totalDiff = total - root.previousStats.total;
                const iowaitDiff = iowait - root.previousStats.iowait;
                if (totalDiff > 0)
                    root.iowait = Math.max(0, Math.min(1, iowaitDiff / totalDiff));
            }
            root.previousStats = {
                total,
                iowait
            };
        }

        if (root.tempPath.length > 0) {
            const tempText = fileTemp.text();
            if (tempText && tempText.length > 0) {
                const value = Number(tempText.trim());
                if (!isNaN(value))
                    root.temp = value / 1000;
            }
        }
    }

    Process {
        id: discoverProc
        command: ["bash", "-c", root.discoverScript]
        running: true
        stdout: StdioCollector {
            id: discoverCollector
            onStreamFinished: {
                for (const line of discoverCollector.text.trim().split("\n")) {
                    const sep = line.indexOf("=");
                    if (sep <= 0)
                        continue;
                    if (line.slice(0, sep) === "temp")
                        root.tempPath = line.slice(sep + 1);
                }
                root.refresh();
            }
        }
    }

    Timer {
        interval: Config.options?.resources?.updateInterval ?? 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    FileView {
        id: fileStat
        path: "/proc/stat"
    }
    FileView {
        id: fileTemp
        path: root.tempPath
    }
}
