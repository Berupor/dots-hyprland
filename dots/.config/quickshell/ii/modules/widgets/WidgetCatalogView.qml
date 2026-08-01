import QtQuick
import QtQuick.Layouts
import qs.modules.common.widgets
import qs.modules.widgets

/**
 * Built-in view of the Widgets settings page. Replaceable via the catalogView slot.
 */
ContentPage {
    forceWidth: true

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 8

        Repeater {
            model: WidgetCatalog.widgets
            delegate: WidgetCard {
                required property var modelData
                manifest: modelData
            }
        }
    }

    WidgetInstallSection {}

    ErrorReportsSection {}
}
