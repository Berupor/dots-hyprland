import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

/**
 * Gpu column in the resources popup: load, vram, temperature.
 */
Column {
    id: root

    visible: GpuStatus.available && Config.options.bar.resources.showGpu
    anchors.top: parent.top
    spacing: 8

    StyledPopupHeaderRow {
        icon: "deployed_code"
        label: "GPU"
    }

    // ColumnLayout, not Column: rows stretch to the widest one so values right-align
    ColumnLayout {
        spacing: 4

        StyledPopupValueRow {
            Layout.fillWidth: true
            icon: "bolt"
            label: Translation.tr("Load:")
            value: `${Math.round(GpuStatus.usage * 100)}%`
        }
        StyledPopupValueRow {
            Layout.fillWidth: true
            icon: "memory_alt"
            label: Translation.tr("VRAM:")
            value: `${Math.round(GpuStatus.vramUsedPercentage * 100)}%`
        }
        StyledPopupValueRow {
            Layout.fillWidth: true
            visible: GpuStatus.temp >= 0
            icon: "thermostat"
            label: Translation.tr("Temp:")
            value: `${Math.round(GpuStatus.temp)}°C`
        }
    }
}
