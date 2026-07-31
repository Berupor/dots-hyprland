pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.widgets
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

/** Right-click-expanded details: percentage custom fields as bar cards, everything else as rows. */
ColumnLayout {
    id: root
    required property var account
    spacing: 8

    readonly property var fields: Statusphere.detailFieldsFor(root.account)
    readonly property var statFields: root.fields.filter(f => f.percent !== null)
    readonly property var textFields: root.fields.filter(f => f.percent === null)

    GridLayout {
        Layout.fillWidth: true
        visible: statCards.count > 0
        columns: 2
        rowSpacing: 8
        columnSpacing: 8

        Repeater {
            id: statCards
            model: root.statFields

            delegate: Rectangle {
                id: card
                required property var modelData
                required property int index

                Layout.preferredWidth: 150
                Layout.fillWidth: true
                Layout.columnSpan: (card.index === statCards.count - 1 && statCards.count % 2 === 1) ? 2 : 1
                implicitHeight: cardContent.implicitHeight + 20
                radius: Appearance.rounding.small
                color: Appearance.colors.colLayer2

                ColumnLayout {
                    id: cardContent
                    anchors {
                        left: parent.left
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                        margins: 10
                    }
                    spacing: 4

                    StyledText {
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        text: card.modelData.label
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colSubtext
                    }
                    StyledText {
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        text: Math.round(card.modelData.percent) + "%"
                        font.pixelSize: Appearance.font.pixelSize.huge
                        color: Appearance.colors.colOnLayer2
                    }
                    StyledProgressBar {
                        Layout.fillWidth: true
                        Layout.topMargin: 4
                        from: 0
                        to: 100
                        value: card.modelData.percent
                        valueBarHeight: 6
                        highlightColor: Appearance.colors.colPrimary
                        trackColor: Appearance.colors.colLayer3
                    }
                }
            }
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 6
        visible: textRows.count > 0

        Repeater {
            id: textRows
            model: root.textFields

            delegate: RowLayout {
                required property var modelData
                Layout.fillWidth: true
                spacing: 6

                MaterialSymbol {
                    text: modelData.icon
                    iconSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colSubtext
                }
                StyledText {
                    Layout.fillWidth: true
                    text: modelData.label
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colSubtext
                }
                StyledText {
                    horizontalAlignment: Text.AlignRight
                    text: modelData.value
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colOnLayer2
                }
            }
        }
    }
}
