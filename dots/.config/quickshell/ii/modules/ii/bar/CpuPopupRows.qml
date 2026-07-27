import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

/**
 * Cpu rows in the resources popup: load, iowait, temperature.
 * ColumnLayout, not Column: rows stretch to the widest one so values right-align,
 * same as the gpu column.
 */
ColumnLayout {
    id: root

    spacing: 4

    StyledPopupValueRow {
        Layout.fillWidth: true
        icon: "bolt"
        label: Translation.tr("Load:")
        value: `${Math.round(ResourceUsage.cpuUsage * 100)}%`
    }
    StyledPopupValueRow {
        Layout.fillWidth: true
        icon: "hourglass_empty"
        label: Translation.tr("I/O wait:")
        value: `${Math.round(CpuStatus.iowait * 100)}%`
    }
    StyledPopupValueRow {
        Layout.fillWidth: true
        visible: CpuStatus.temp >= 0
        icon: "thermostat"
        label: Translation.tr("Temp:")
        value: `${Math.round(CpuStatus.temp)}°C`
    }
}
