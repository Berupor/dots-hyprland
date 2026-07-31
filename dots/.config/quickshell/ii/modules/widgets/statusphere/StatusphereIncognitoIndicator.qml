pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.widgets
import qs.modules.common.widgets
import qs.services
import QtQuick

/** Reminder that your room can't see you. Click to come back. */
MouseArea {
    id: root

    property bool shown: Statusphere.hiding && Statusphere.opt("incognitoIndicator")
    visible: shown
    implicitWidth: visible ? icon.implicitWidth : 0
    implicitHeight: Appearance.sizes.barHeight
    hoverEnabled: !Config.options.bar.tooltips.clickToShow
    onClicked: Statusphere.setIncognito(false, 0)

    MaterialSymbol {
        id: icon
        anchors.centerIn: parent
        fill: 0 // Outline, like the indicators next to it - filled turns to mush at this size
        text: "visibility_off"
        iconSize: Appearance.font.pixelSize.larger
        color: Appearance.colors.colOnLayer1

        StyledToolTip {
            extraVisibleCondition: false
            alternativeVisibleCondition: root.containsMouse
            text: `${Statusphere.incognitoLabel()}\n${Translation.tr("Click to be visible again")}`
        }
    }
}
