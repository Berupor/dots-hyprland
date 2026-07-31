import qs.modules.widgets
import qs.services

WidgetManifest {
    widgetId: "androidWebcam"
    name: Translation.tr("Android webcam")
    description: Translation.tr("Indicator for a phone attached as a USB webcam")
    icon: "mobile_camera"
    slots: ({ "barIndicator": "AndroidWebcamIndicator.qml" })
}
