import qs.modules.common
import qs.modules.common.widgets
import QtQuick

/** Sibling type of an external widget: resolves without any import. */
Rectangle {
    implicitWidth: label.implicitWidth + 8
    implicitHeight: label.implicitHeight + 2
    radius: Appearance.rounding.verysmall
    color: Appearance.colors.colSecondaryContainer

    StyledText {
        id: label
        anchors.centerIn: parent
        text: "1"
        font.pixelSize: Appearance.font.pixelSize.smaller
        color: Appearance.colors.colOnSecondaryContainer
    }
}
