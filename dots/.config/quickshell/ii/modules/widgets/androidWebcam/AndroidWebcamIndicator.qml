pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

/** Phone-as-webcam indicator: one icon, zero width while no phone is attached. */
MouseArea {
    id: root

    visible: AndroidWebcam.active
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
