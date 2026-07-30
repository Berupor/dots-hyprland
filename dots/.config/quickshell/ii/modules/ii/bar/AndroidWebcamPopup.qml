pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

/** Which phone is the webcam, and which /dev/video* node it took. */
StyledPopup {
    id: root

    Column {
        anchors.centerIn: parent
        spacing: 8

        StyledPopupHeaderRow {
            icon: "smartphone"
            label: AndroidWebcam.model !== "" ? AndroidWebcam.model : Translation.tr("Android phone")
        }

        // ColumnLayout, not Column: rows stretch to the widest one so values right-align
        ColumnLayout {
            spacing: 4

            StyledPopupValueRow {
                Layout.fillWidth: true
                icon: "videocam"
                label: Translation.tr("Mode:")
                value: Translation.tr("USB webcam")
            }
            StyledPopupValueRow {
                Layout.fillWidth: true
                icon: "cable"
                label: AndroidWebcam.devices.length > 1 ? Translation.tr("Nodes:") : Translation.tr("Node:")
                value: AndroidWebcam.devicePaths
            }
        }
    }
}
