pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

/**
 * Peripheral battery popup: every device with percentage, state and time left
 * (when UPower reports it, which hid++ mice usually don't).
 */
StyledPopup {
    id: root

    Column {
        anchors.centerIn: parent
        spacing: 12

        Repeater {
            model: PeripheralBattery.devices

            delegate: Column {
                id: deviceColumn
                required property var modelData

                spacing: 8

                StyledPopupHeaderRow {
                    icon: PeripheralBattery.iconFor(deviceColumn.modelData.type)
                    label: PeripheralBattery.nameFor(deviceColumn.modelData)
                }

                // ColumnLayout, not Column: rows stretch to the widest one so values right-align
                ColumnLayout {
                    spacing: 4

                    StyledPopupValueRow {
                        Layout.fillWidth: true
                        icon: PeripheralBattery.isLow(deviceColumn.modelData) ? "battery_android_alert" : "battery_android_full"
                        label: Translation.tr("Charge:")
                        value: `${Math.round(deviceColumn.modelData.percentage * 100)}%`
                    }
                    StyledPopupValueRow {
                        Layout.fillWidth: true
                        icon: "bolt"
                        label: Translation.tr("State:")
                        value: PeripheralBattery.stateString(deviceColumn.modelData)
                    }
                    StyledPopupValueRow {
                        Layout.fillWidth: true
                        visible: deviceColumn.modelData.timeToEmpty > 0
                        icon: "schedule"
                        label: Translation.tr("Time left:")
                        value: PeripheralBattery.durationString(deviceColumn.modelData.timeToEmpty)
                    }
                    StyledPopupValueRow {
                        Layout.fillWidth: true
                        visible: deviceColumn.modelData.timeToFull > 0
                        icon: "schedule"
                        label: Translation.tr("Until full:")
                        value: PeripheralBattery.durationString(deviceColumn.modelData.timeToFull)
                    }
                }
            }
        }
    }
}
