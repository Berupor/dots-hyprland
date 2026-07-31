import qs.modules.ii.bar
import qs.modules.widgets
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
    shown: GpuStatus.available && WidgetCatalog.isEnabled("gpu")
    warning: GpuStatus.temp >= (WidgetCatalog.option("gpu", "hotTemp") ?? 95)
    Layout.leftMargin: root.shown ? 6 : 0
}
