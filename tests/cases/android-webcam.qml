//@ probe -g 240x60 -s 1200
/**
 * What the auto-switch reads out of `adb devices -l`, and what the widget makes of a
 * webcam node. The widget is left off on purpose: enabled, its own scan would clear
 * the devices set here.
 */
import qs.modules.widgets
import QtQuick

Item {
    id: probe

    readonly property string listing: `List of devices attached
1A2B3C4D               device usb:1-3 product:raven model:Pixel_6_Pro device:raven transport_id:5
9Z8Y7X6W               offline usb:1-4 product:bluejay model:Pixel_6a device:bluejay transport_id:6
FA7700112233           unauthorized usb:1-5 transport_id:8
EMULATOR30             device product:sdk_gphone64 model:sdk_gphone64_x86_64 transport_id:12`

    readonly property var all: AndroidWebcam.candidates(probe.listing, "")
    readonly property var filtered: AndroidWebcam.candidates(probe.listing, "Pixel 6 Pro")

    function checks() {
        return [
            {
                // Offline and unauthorized phones cannot be told to do anything
                "name": "only authorized devices are candidates",
                "got": probe.all.map(d => d.model),
                "want": ["Pixel 6 Pro", "sdk gphone64 x86 64"]
            },
            {
                // The serial repeats across replugs, the transport id does not
                "name": "keyed by serial and transport id",
                "got": probe.all[0]?.key ?? "",
                "want": "1A2B3C4D:5"
            },
            {
                "name": "the model option narrows it to one phone",
                "got": probe.filtered.map(d => d.key),
                "want": ["1A2B3C4D:5"]
            },
            {
                "name": "a listing with no phones asks for nothing",
                "got": AndroidWebcam.candidates("List of devices attached\n", "").length,
                "want": 0
            },
            {
                "name": "two nodes read as one phone with two of them",
                "got": [AndroidWebcam.model, AndroidWebcam.devicePaths, AndroidWebcam.active],
                "want": ["Pixel 6 Pro", "/dev/video0, /dev/video1", true]
            }
        ];
    }

    Component.onCompleted: AndroidWebcam.devices = [
        {
            path: "/dev/video0",
            model: "Pixel 6 Pro"
        },
        {
            path: "/dev/video1",
            model: "Pixel 6 Pro"
        }
    ]
}
