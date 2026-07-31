pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.widgets
import qs.modules.widgets
import QtQuick
import QtQuick.Layouts

/** Phone-as-webcam indicator: one icon, zero width while no phone is attached. */
MouseArea {
    id: root

    property bool shown: AndroidWebcam.active
    visible: shown
    implicitWidth: visible ? icon.implicitWidth : 0
    implicitHeight: Appearance.sizes.barHeight
    hoverEnabled: !Config.options.bar.tooltips.clickToShow

    MaterialSymbol {
        id: icon
        anchors.centerIn: parent
        fill: 0
        text: "mobile_camera"
        iconSize: Appearance.font.pixelSize.larger
        color: Appearance.colors.colOnLayer1
    }

    AndroidWebcamPopup {
        hoverTarget: root
    }
}
