pragma Singleton
pragma ComponentBehavior: Bound

/** A phone attached as a USB webcam (Android UVC gadget mode). */

// Detection is host-side: the kernel names such a node "<model>: Android Webcam".
// Flipping the phone into that mode needs adb and is opt-in, see the autoSwitch option.

import qs.services
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property bool enabled: WidgetCatalog.isEnabled("androidWebcam")

    function opt(key) {
        return WidgetCatalog.option("androidWebcam", key);
    }

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

    // Event-driven instead of polling. usb too: switching functions re-enumerates the phone
    Process {
        id: udevMonitor
        running: root.enabled
        command: ["udevadm", "monitor", "--udev", "--subsystem-match=video4linux", "--subsystem-match=usb"]
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

    /* Auto-switch: `svc usb setFunctions uvc` over adb, what one would otherwise
       do by hand on every plug. Off by default, it takes over the phone's USB mode. */

    readonly property bool autoSwitch: root.enabled && (root.opt("autoSwitch") ?? false)
    readonly property string wantedModel: root.opt("model") ?? ""
    readonly property bool notifies: root.opt("notify") ?? true
    readonly property int pollSeconds: root.opt("pollSeconds") ?? 5
    readonly property int maxAttempts: 3 // Android refuses on a locked screen, asking forever is noise

    // Keyed by "serial:transport_id": the serial survives a replug, the transport id does
    // not, so a quick replug between polls counts as a new connection and gets another try
    property var handled: ({})
    property var attempts: ({})

    property string pendingKey: ""
    property string pendingModel: ""

    Timer {
        interval: Math.max(2, root.pollSeconds) * 1000
        repeat: true
        triggeredOnStart: true
        running: root.autoSwitch && !root.active && root.pendingKey === ""
        onTriggered: if (!listProc.running) listProc.running = true
    }

    Process {
        id: listProc
        command: ["adb", "devices", "-l"]
        stdout: StdioCollector {
            id: listCollector
            onStreamFinished: root.onDevicesListed(listCollector.text)
        }
    }

    /// Phones we may switch, from lines of "serial device ... model:Pixel_6_Pro
    /// transport_id:5" under a header. Anything offline or unauthorized is not one
    function candidates(text, wantedModel) {
        const found = [];
        for (const line of text.trim().split("\n").slice(1)) {
            const parts = line.trim().split(/\s+/);
            if (parts.length < 2 || parts[1] !== "device")
                continue;
            let model = "";
            let tid = "";
            for (const part of parts.slice(2)) {
                if (part.startsWith("model:"))
                    model = part.slice(6).replace(/_/g, " ");
                else if (part.startsWith("transport_id:"))
                    tid = part.slice(13);
            }
            if (tid === "" || (wantedModel !== "" && model !== wantedModel))
                continue;
            found.push({
                key: `${parts[0]}:${tid}`,
                tid: tid,
                model: model
            });
        }
        return found;
    }

    function onDevicesListed(text): void {
        const live = root.candidates(text, root.wantedModel);

        // Gone connections are forgotten, so plugging back in tries again
        const handled = {};
        const attempts = {};
        for (const device of live) {
            if (root.handled[device.key])
                handled[device.key] = true;
            if (root.attempts[device.key])
                attempts[device.key] = root.attempts[device.key];
        }
        root.handled = handled;
        root.attempts = attempts;

        if (root.pendingKey !== "" || root.active)
            return;
        for (const device of live) {
            if (root.handled[device.key] || (root.attempts[device.key] ?? 0) >= root.maxAttempts)
                continue;
            root.switchOver(device);
            return;
        }
    }

    function switchOver(device): void {
        root.attempts[device.key] = (root.attempts[device.key] ?? 0) + 1;
        root.pendingKey = device.key;
        root.pendingModel = device.model;
        switchProc.command = ["adb", "-t", device.tid, "shell", "svc", "usb", "setFunctions", "uvc"];
        switchProc.running = true;
        uvcWait.restart();
    }

    Process {
        id: switchProc
    }

    Timer {
        id: uvcWait
        interval: 10000 // Changing functions drops USB, the node is back a few seconds later
        onTriggered: root.settle(false)
    }

    onActiveChanged: if (root.active) root.settle(true)

    function settle(ok): void {
        uvcWait.stop();
        const key = root.pendingKey;
        if (key === "")
            return;
        root.pendingKey = "";
        const name = root.pendingModel !== "" ? root.pendingModel : Translation.tr("Android phone");
        if (ok) {
            root.handled[key] = true;
            root.notify(Translation.tr("Phone is a webcam"), Translation.tr("%1 switched to USB webcam mode").arg(name));
        } else if ((root.attempts[key] ?? 0) >= root.maxAttempts) {
            root.handled[key] = true;
            root.notify(Translation.tr("Webcam switch failed"), Translation.tr("%1 exposed no UVC device").arg(name));
        }
    }

    function notify(summary, body): void {
        if (!root.notifies)
            return;
        // synchronous hint: a new toast replaces the old one instead of stacking up
        Quickshell.execDetached(["notify-send", "-a", "android-webcam", "-h", "string:x-canonical-private-synchronous:android-webcam", summary, body]);
    }

    // adb is only needed for the switch, so it is no widget dependency. Say it once
    // instead: with the option on and no adb nothing would ever happen
    Process {
        running: root.autoSwitch
        command: ["bash", "-c", "command -v adb >/dev/null"]
        onExited: code => {
            if (code !== 0)
                Quickshell.execDetached(["notify-send", "-a", "android-webcam", Translation.tr("Android webcam"), Translation.tr("Switching needs adb, install android-tools")]);
        }
    }
}
