import qs.modules.widgets
import qs.services

WidgetManifest {
    widgetId: "androidWebcam"
    name: Translation.tr("Android webcam")
    description: Translation.tr("Indicator for a phone attached as a USB webcam")
    icon: "mobile_camera"
    minShellVersion: "1.1" // textField option
    slots: ({ "barIndicator": "AndroidWebcamIndicator.qml" })
    options: [
        {
            key: "autoSwitch",
            type: "switch",
            label: Translation.tr("Put a plugged phone in webcam mode"),
            icon: "usb",
            default: false
        },
        {
            key: "model",
            type: "textField",
            label: Translation.tr("Only this phone"),
            icon: "smartphone",
            placeholder: Translation.tr("Any adb device"),
            default: ""
        },
        {
            key: "pollSeconds",
            type: "spinBox",
            label: Translation.tr("Look for it every, s"),
            icon: "timer",
            min: 2,
            max: 60,
            default: 5
        },
        {
            key: "notify",
            type: "switch",
            label: Translation.tr("Notify when switched"),
            icon: "notifications",
            default: true
        }
    ]
}
