pragma Singleton
pragma ComponentBehavior: Bound

/** A phone attached as a USB webcam (Android UVC gadget mode). */

// Host-side detection only: the kernel names such a node "<model>: Android Webcam".
// No adb, no helper daemon - without a phone there is simply no node.

import qs.modules.common
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property bool enabled: Config.options.bar.androidWebcam.enable

    // [{ path: "/dev/video0", model: "Pixel 6 Pro" }, ...]
    property var devices: []
    readonly property bool active: root.devices.length > 0
    readonly property string model: root.active ? root.devices[0].model : ""
    readonly property string devicePaths: root.devices.map(d => d.path).join(", ")

    function rescan(): void {
        if (root.enabled)
            scanProc.running = true;
    }

    Component.onCompleted: root.rescan()
    onEnabledChanged: root.enabled ? root.rescan() : root.devices = []

    Process {
        id: scanProc
        command: ["bash", "-c", `for n in /sys/class/video4linux/*/name; do [ -r "$n" ] || continue; name=$(cat "$n"); case "$name" in *"Android Webcam"*) printf '%s\\t%s\\n' "$(basename "$(dirname "$n")")" "$name";; esac; done`]
        stdout: StdioCollector {
            id: scanCollector
            onStreamFinished: {
                const found = [];
                for (const line of scanCollector.text.trim().split("\n")) {
                    if (line === "")
                        continue;
                    const [node, name] = line.split("\t");
                    found.push({
                        path: `/dev/${node}`,
                        model: (name ?? "").replace(/:?\s*Android Webcam\s*$/, "").trim()
                    });
                }
                root.devices = found;
            }
        }
    }

    // Event-driven instead of polling
    Process {
        id: udevMonitor
        running: root.enabled
        command: ["udevadm", "monitor", "--udev", "--subsystem-match=video4linux"]
        stdout: SplitParser {
            onRead: debounce.restart() // Nodes land a moment after the event
        }
    }

    Timer {
        id: debounce
        interval: 500
        onTriggered: root.rescan()
    }

    // Fallback for a missing udevadm
    Timer {
        interval: 15000
        repeat: true
        running: root.enabled && !udevMonitor.running
        onTriggered: root.rescan()
    }
}
