import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.widgets

/**
 * Built-in view of the Widgets settings page. Replaceable via the catalogView slot.
 */
ContentPage {
    id: root
    readonly property bool catalogEmpty: WidgetCatalog.widgets.length === 0

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

        Item { // Nothing to list yet, so the card below is the whole page
            Layout.fillWidth: true
            Layout.topMargin: 20
            Layout.bottomMargin: 12
            visible: root.catalogEmpty
            implicitHeight: 200

            PagePlaceholder {
                icon: "widgets"
                title: Translation.tr("No widgets yet")
                description: Translation.tr("Every widget is a git repository of its own.\nInstall one below and it lands here.")
                shape: MaterialShape.Shape.Cookie9Sided
                descriptionHorizontalAlignment: Text.AlignHCenter
            }
        }

        Rectangle { // Below it the page settles its own business, not a widget's
            Layout.fillWidth: true
            Layout.leftMargin: 14
            Layout.rightMargin: 14
            Layout.topMargin: 10
            Layout.bottomMargin: 6
            visible: !root.catalogEmpty
            implicitHeight: 1
            color: Appearance.colors.colOutlineVariant
        }

        InstallCard {
            expanded: root.catalogEmpty // The one thing to do here, so it opens itself
        }

        ErrorReportsCard {}
    }
}
