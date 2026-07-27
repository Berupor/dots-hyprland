pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

/**
 * Peripheral battery in the bar: a circle per device with its icon and percentage.
 *
 * All devices by default, otherwise a connected headset silently hides behind an
 * emptier mouse. showAll: false keeps a single circle, the emptiest one.
 */
MouseArea {
    id: root

    property bool showAll: Config.options.bar.peripheralBattery.showAll
    readonly property int circleSize: 20
    readonly property var shownDevices: {
        if (PeripheralBattery.count === 0)
            return [];
        return root.showAll ? PeripheralBattery.devices : [PeripheralBattery.devices[0]];
    }

    visible: PeripheralBattery.count > 0
    implicitWidth: visible ? rowLayout.implicitWidth : 0
    implicitHeight: Appearance.sizes.barHeight
    hoverEnabled: !Config.options.bar.tooltips.clickToShow

    RowLayout {
        id: rowLayout
        anchors.centerIn: parent
        spacing: 6

        Repeater {
            model: root.shownDevices

            delegate: RowLayout {
                id: deviceRow
                required property var modelData

                readonly property bool low: PeripheralBattery.isLow(deviceRow.modelData)
                readonly property bool charging: PeripheralBattery.isCharging(deviceRow.modelData)

                spacing: 2

                ClippedFilledCircularProgress {
                    id: circProg
                    Layout.alignment: Qt.AlignVCenter
                    implicitSize: root.circleSize
                    lineWidth: Appearance.rounding.unsharpen
                    value: deviceRow.modelData.percentage
                    enableAnimation: false
                    accountForLightBleeding: !deviceRow.low
                    colPrimary: {
                        if (deviceRow.low)
                            return Appearance.colors.colError;
                        if (deviceRow.charging)
                            return Appearance.colors.colPrimary;
                        return Appearance.colors.colOnSecondaryContainer;
                    }

                    // Device icon is cut out of the filled circle
                    Item {
                        width: circProg.implicitSize
                        height: circProg.implicitSize

                        MaterialSymbol {
                            anchors.centerIn: parent
                            font.weight: Font.DemiBold
                            fill: 1
                            text: PeripheralBattery.iconFor(deviceRow.modelData.type)
                            iconSize: Appearance.font.pixelSize.normal
                            color: Appearance.m3colors.m3onSecondaryContainer
                        }
                    }
                }

                Item {
                    Layout.alignment: Qt.AlignVCenter
                    implicitWidth: fullPercentageTextMetrics.width
                    implicitHeight: percentageText.implicitHeight

                    TextMetrics {
                        id: fullPercentageTextMetrics
                        text: "100"
                        font.pixelSize: Appearance.font.pixelSize.small
                    }

                    StyledText {
                        id: percentageText
                        anchors.centerIn: parent
                        color: deviceRow.low ? Appearance.colors.colError : Appearance.colors.colOnLayer1
                        font.pixelSize: Appearance.font.pixelSize.small
                        text: `${Math.round(deviceRow.modelData.percentage * 100)}`
                    }
                }
            }
        }
    }

    PeripheralBatteryPopup {
        hoverTarget: root
    }
}
