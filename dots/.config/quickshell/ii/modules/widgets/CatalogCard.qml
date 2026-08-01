import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

/**
 * List item of the widgets page: header with icon and subtitle, body behind a disclosure.
 */
Rectangle {
    id: root
    property string icon
    property string title
    property string subtitle
    property color iconColor: Appearance.colors.colSurfaceContainerHighest
    property color iconSymbolColor: Appearance.colors.colOnSurfaceVariant
    property real iconOpacity: 1
    property color titleColor: Appearance.colors.colOnLayer2
    property real titleOpacity: 1
    property color subtitleColor: Appearance.colors.colSubtext
    property bool canExpand: true
    property bool expanded: false
    readonly property bool bodyShown: root.canExpand && root.expanded

    property alias headerLeading: headerLeadingRow.data // Before the chevron
    property alias headerTrailing: headerTrailingRow.data // After it
    default property alias bodyData: bodyContent.data

    Layout.fillWidth: true
    implicitHeight: cardColumn.implicitHeight
    radius: Appearance.rounding.large
    color: Appearance.colors.colLayer3

    ColumnLayout {
        id: cardColumn
        width: parent.width
        spacing: 0

        Item { // Header
            Layout.fillWidth: true
            implicitHeight: headerRow.implicitHeight + 12 * 2

            Rectangle {
                anchors.fill: parent
                radius: root.radius
                color: Appearance.colors.colOnLayer2
                opacity: headerArea.containsMouse ? 0.06 : 0
                Behavior on opacity {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
            }

            MouseArea {
                id: headerArea
                anchors.fill: parent
                hoverEnabled: true
                enabled: root.canExpand
                cursorShape: Qt.PointingHandCursor
                onClicked: root.expanded = !root.expanded
            }

            RowLayout {
                id: headerRow
                anchors {
                    left: parent.left
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                    leftMargin: 14
                    rightMargin: 14
                }
                spacing: 14

                MaterialShapeWrappedMaterialSymbol {
                    Layout.alignment: Qt.AlignVCenter
                    text: root.icon
                    iconSize: Appearance.font.pixelSize.hugeass
                    padding: 10
                    opacity: root.iconOpacity
                    color: root.iconColor
                    colSymbol: root.iconSymbolColor

                    Behavior on color {
                        animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    StyledText {
                        Layout.fillWidth: true
                        text: root.title
                        font.pixelSize: Appearance.font.pixelSize.large
                        font.weight: Font.Medium
                        color: root.titleColor
                        elide: Text.ElideRight
                        opacity: root.titleOpacity
                    }

                    StyledText {
                        Layout.fillWidth: true
                        visible: root.subtitle !== ""
                        text: root.subtitle
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: root.subtitleColor
                        wrapMode: Text.WordWrap
                    }
                }

                RowLayout {
                    id: headerLeadingRow
                    Layout.alignment: Qt.AlignVCenter
                    visible: children.length > 0
                    spacing: 14
                }

                MaterialSymbol {
                    Layout.alignment: Qt.AlignVCenter
                    opacity: root.canExpand ? 1 : 0
                    text: "keyboard_arrow_down"
                    iconSize: Appearance.font.pixelSize.huge
                    color: Appearance.colors.colOnSurfaceVariant
                    rotation: root.expanded ? 180 : 0

                    Behavior on rotation {
                        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                    }
                    Behavior on opacity {
                        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                    }
                }

                RowLayout {
                    id: headerTrailingRow
                    Layout.alignment: Qt.AlignVCenter
                    visible: children.length > 0
                    spacing: 14
                }
            }
        }

        Item { // Body
            Layout.fillWidth: true
            clip: true
            implicitHeight: root.bodyShown ? bodyColumn.implicitHeight : 0
            visible: implicitHeight > 0

            Behavior on implicitHeight {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }

            ColumnLayout {
                id: bodyColumn
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    leftMargin: 14
                    rightMargin: 14
                }
                spacing: 2

                Rectangle {
                    Layout.fillWidth: true
                    Layout.bottomMargin: 8
                    implicitHeight: 1
                    color: Appearance.colors.colOutlineVariant
                }

                ColumnLayout {
                    id: bodyContent
                    Layout.fillWidth: true
                    spacing: 2
                }

                Item {
                    implicitHeight: 8
                }
            }
        }
    }
}
