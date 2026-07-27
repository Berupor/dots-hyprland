pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

/**
 * Bottom group tab: a row per peripheral, filled up to its charge.
 *
 * Rows grow to share the panel instead of huddling in the middle, and a grown one moves
 * its state and percentage into the corners. Many devices shrink them back to one line.
 */
Item {
    id: root

    readonly property int minRowHeight: 56
    readonly property int maxRowHeight: 96
    readonly property int rowSpacing: 6
    readonly property int rowPadding: 18
    readonly property int rowHeight: {
        const available = flickable.height - root.rowSpacing * (PeripheralBattery.count - 1);
        return Math.max(root.minRowHeight, Math.min(root.maxRowHeight, available / PeripheralBattery.count));
    }

    PagePlaceholder {
        shown: PeripheralBattery.count === 0
        icon: "mouse"
        description: Translation.tr("No devices with a battery")
        shape: MaterialShape.Shape.Ghostish
        descriptionHorizontalAlignment: Text.AlignHCenter
    }

    StyledFlickable {
        id: flickable
        anchors {
            fill: parent
            rightMargin: 10
            bottomMargin: 10
        }
        contentHeight: deviceColumn.implicitHeight
        clip: true

        ColumnLayout {
            id: deviceColumn
            width: flickable.width
            // Centered while the rows fit, scrolled once they don't
            y: Math.max(0, (flickable.height - deviceColumn.implicitHeight) / 2)
            spacing: root.rowSpacing

            Repeater {
                model: PeripheralBattery.devices

                delegate: Rectangle {
                    id: deviceRow
                    required property var modelData

                    readonly property bool low: PeripheralBattery.isLow(deviceRow.modelData)
                    readonly property bool charging: PeripheralBattery.isCharging(deviceRow.modelData)
                    // Room for the state and percentage to sit in their own corners
                    readonly property bool grown: deviceRow.height >= 84

                    Layout.fillWidth: true
                    Layout.preferredHeight: root.rowHeight
                    radius: Math.min(deviceRow.height / 2, Appearance.rounding.verylarge)
                    color: Appearance.colors.colLayer2

                    // Charge as the row's own fill, like Android's battery widget
                    Rectangle {
                        anchors {
                            left: parent.left
                            top: parent.top
                            bottom: parent.bottom
                        }
                        width: Math.max(parent.radius * 2, parent.width * deviceRow.modelData.percentage)
                        radius: parent.radius
                        color: deviceRow.low ? Appearance.colors.colErrorContainer : Appearance.colors.colSecondaryContainer

                        Behavior on width {
                            animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
                        }
                    }

                    Item {
                        id: content
                        anchors {
                            fill: parent
                            margins: root.rowPadding
                        }

                        RowLayout {
                            id: nameRow
                            anchors {
                                left: parent.left
                                right: parent.right
                                top: parent.top
                            }
                            spacing: 12

                            MaterialSymbol {
                                Layout.alignment: Qt.AlignVCenter
                                text: PeripheralBattery.iconFor(deviceRow.modelData.type)
                                iconSize: Appearance.font.pixelSize.hugeass
                                color: Appearance.colors.colOnLayer2
                            }

                            StyledText {
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                color: Appearance.colors.colOnLayer2
                                text: PeripheralBattery.nameFor(deviceRow.modelData)
                            }

                            MaterialSymbol {
                                Layout.alignment: Qt.AlignVCenter
                                visible: deviceRow.charging
                                fill: 1
                                text: "bolt"
                                iconSize: Appearance.font.pixelSize.hugeass
                                color: Appearance.colors.colOnLayer2
                            }
                        }

                        StyledText {
                            id: detailText
                            visible: deviceRow.grown && detailText.text.length > 0
                            anchors {
                                left: parent.left
                                right: percentageText.left
                                rightMargin: 12
                                baseline: percentageText.baseline
                            }
                            elide: Text.ElideRight
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colOnLayer2
                            text: PeripheralBattery.detailFor(deviceRow.modelData)
                        }

                        StyledText {
                            id: percentageText
                            anchors {
                                right: parent.right
                                bottom: parent.bottom
                            }
                            font.pixelSize: deviceRow.grown ? Appearance.font.pixelSize.huge : Appearance.font.pixelSize.large
                            color: Appearance.colors.colOnLayer2
                            text: `${Math.round(deviceRow.modelData.percentage * 100)}%`
                        }

                        // One line when the row is too short for corners
                        states: State {
                            name: "compact"
                            when: !deviceRow.grown

                            AnchorChanges {
                                target: nameRow
                                anchors.top: undefined
                                anchors.right: percentageText.left
                                anchors.verticalCenter: content.verticalCenter
                            }
                            AnchorChanges {
                                target: percentageText
                                anchors.bottom: undefined
                                anchors.verticalCenter: content.verticalCenter
                            }
                            PropertyChanges {
                                nameRow.anchors.rightMargin: 12
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: !deviceRow.grown // Grown rows show the state already

                        StyledToolTip {
                            extraVisibleCondition: false
                            alternativeVisibleCondition: parent.containsMouse
                            text: PeripheralBattery.detailFor(deviceRow.modelData)
                        }
                    }
                }
            }
        }
    }
}
