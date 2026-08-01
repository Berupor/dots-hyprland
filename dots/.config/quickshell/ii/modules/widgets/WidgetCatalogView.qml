import QtQuick
import QtQuick.Layouts
import qs.modules.common
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

        Rectangle { // Below it the page settles its own business, not a widget's
            Layout.fillWidth: true
            Layout.leftMargin: 14
            Layout.rightMargin: 14
            Layout.topMargin: 10
            Layout.bottomMargin: 6
            implicitHeight: 1
            color: Appearance.colors.colOutlineVariant
        }

        InstallCard {}

        ErrorReportsCard {}
    }
}
