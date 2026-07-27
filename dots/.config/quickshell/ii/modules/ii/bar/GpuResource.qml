import qs.modules.common
import qs.services
import QtQuick
import QtQuick.Layouts

/**
 * Gpu usage circle, a plain upstream Resource living inside the ram/swap/cpu group.
 */
Resource {
    id: root

    // A cube reads as 3d/graphics; developer_board and memory_alt read as a ram chip
    iconName: "deployed_code"
    percentage: GpuStatus.usage
    shown: GpuStatus.available && Config.options.bar.resources.showGpu
    warning: GpuStatus.temp >= Config.options.bar.resources.gpuHotTemp
    Layout.leftMargin: root.shown ? 6 : 0
}
