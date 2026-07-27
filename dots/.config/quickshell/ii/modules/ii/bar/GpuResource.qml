import qs.modules.common
import qs.services
import QtQuick
import QtQuick.Layouts

/**
 * Gpu usage circle, a plain upstream Resource living inside the ram/swap/cpu group.
 */
Resource {
    id: root

    // Warn on heat, not on load: 100% while rendering is normal
    property int hotTemp: 95

    // A cube reads as 3d/graphics; developer_board and memory_alt read as a ram chip
    iconName: "deployed_code"
    percentage: GpuStatus.usage
    shown: GpuStatus.available
    warning: GpuStatus.temp >= root.hotTemp
    Layout.leftMargin: root.shown ? 6 : 0
}
