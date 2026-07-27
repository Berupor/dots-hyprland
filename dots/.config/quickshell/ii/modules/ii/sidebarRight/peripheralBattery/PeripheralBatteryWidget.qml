pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

/**
 * Bottom group tab: a panel of cards, one per peripheral, filled up to its charge.
 * A lone device takes the whole panel and scales its type up with it.
 */
Item {
    id: root

    readonly property bool single: PeripheralBattery.count === 1
    readonly property int cardSpacing: 8
    readonly property int cardPadding: root.single ? 20 : 12

    PagePlaceholder {
        shown: PeripheralBattery.count === 0
        icon: "mouse"
        description: Translation.tr("No devices with a battery")
        shape: MaterialShape.Shape.Ghostish
        descriptionHorizontalAlignment: Text.AlignHCenter
    }

    Rectangle {
        id: panel
        visible: PeripheralBattery.count > 0
        anchors {
            fill: parent
            topMargin: 10
            rightMargin: 10
            bottomMargin: 10
        }
        radius: Appearance.rounding.large
        color: Appearance.colors.colLayer2

        StyledFlickable {
            id: flickable
            anchors {
                fill: parent
                margins: 12
            }
            contentHeight: deviceColumn.height
            clip: true

            ColumnLayout {
                id: deviceColumn
                width: flickable.width
                height: root.single ? flickable.height : implicitHeight
                spacing: root.cardSpacing

                Repeater {
                    model: PeripheralBattery.devices

                    delegate: Rectangle {
                        id: card
                        required property var modelData

                        readonly property bool low: PeripheralBattery.isLow(card.modelData)
                        readonly property bool charging: PeripheralBattery.isCharging(card.modelData)

                        Layout.fillWidth: true
                        Layout.fillHeight: root.single
                        implicitHeight: root.cardPadding * 2 + cardRow.implicitHeight
                        radius: Appearance.rounding.normal
                        color: Appearance.colors.colLayer3

                        // Charge as the card's own fill, like Android's battery widget
                        Rectangle {
                            anchors {
                                left: parent.left
                                top: parent.top
                                bottom: parent.bottom
                            }
                            width: Math.max(parent.radius * 2, parent.width * card.modelData.percentage)
                            radius: parent.radius
                            color: card.low ? Appearance.colors.colErrorContainer : Appearance.colors.colSecondaryContainer

                            Behavior on width {
                                animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
                            }
                        }

                        RowLayout {
                            id: cardRow
                            anchors {
                                left: parent.left
                                right: parent.right
                                verticalCenter: parent.verticalCenter
                                leftMargin: root.cardPadding
                                rightMargin: root.cardPadding
                            }
                            spacing: 12

                            MaterialSymbol {
                                Layout.alignment: Qt.AlignVCenter
                                text: PeripheralBattery.iconFor(card.modelData.type)
                                iconSize: root.single ? 36 : 26
                                color: Appearance.colors.colOnLayer2
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0

                                StyledText {
                                    id: nameText
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                    font.pixelSize: root.single ? Appearance.font.pixelSize.normal : Appearance.font.pixelSize.small
                                    color: Appearance.colors.colOnLayer2
                                    text: PeripheralBattery.nameFor(card.modelData)
                                }

                                StyledText {
                                    id: detailText
                                    Layout.fillWidth: true
                                    visible: detailText.text.length > 0
                                    elide: Text.ElideRight
                                    font.pixelSize: root.single ? Appearance.font.pixelSize.smallie : Appearance.font.pixelSize.smaller
                                    color: Appearance.colors.colOnLayer1
                                    text: PeripheralBattery.detailFor(card.modelData)
                                }
                            }

                            MaterialSymbol {
                                Layout.alignment: Qt.AlignVCenter
                                visible: card.charging
                                fill: 1
                                text: "bolt"
                                iconSize: root.single ? 30 : Appearance.font.pixelSize.hugeass
                                color: Appearance.colors.colOnLayer2
                            }

                            StyledText {
                                Layout.alignment: Qt.AlignVCenter
                                font.pixelSize: root.single ? 32 : Appearance.font.pixelSize.huge
                                color: Appearance.colors.colOnLayer2
                                text: `${Math.round(card.modelData.percentage * 100)}%`
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: nameText.truncated || detailText.truncated

                            StyledToolTip {
                                extraVisibleCondition: false
                                alternativeVisibleCondition: parent.containsMouse
                                text: `${PeripheralBattery.nameFor(card.modelData)}\n${PeripheralBattery.detailFor(card.modelData)}`
                            }
                        }
                    }
                }
            }
        }
    }
}
