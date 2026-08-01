pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.modules.widgets

/**
 * Every enabled catalog widget in a slot, one Loader each. For slots whose
 * value is a plain path; the ones carrying a name or an icon load by hand.
 */
Repeater {
    id: root
    required property string slot
    /// Passed to the widget on load, for slots that hand it context
    property var initialProperties: null
    /// Host-side gate, on top of the widget's own `shown`
    property bool shown: true
    /// Gap after each item, in a layout
    property real spacing: 0

    model: WidgetCatalog.forSlot(root.slot)
    delegate: Loader {
        required property var modelData
        Layout.alignment: Qt.AlignVCenter
        Layout.rightMargin: root.spacing
        visible: root.shown && (item?.shown ?? true)
        // setSource, not source: initialProperties only land through it
        Component.onCompleted: setSource(modelData.resolve(modelData.slots[root.slot]), root.initialProperties ?? {})
        onStatusChanged: if (status === Loader.Error) ErrorReporter.report(modelData.widgetId, `${source} failed to load`)
    }
}
