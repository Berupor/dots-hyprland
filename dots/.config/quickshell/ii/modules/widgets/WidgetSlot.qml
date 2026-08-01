pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.modules.widgets

/**
 * Every enabled catalog widget in a slot, one Loader each. Widgets that don't
 * draw for the host's orientation stay out; the slots carrying a name or an
 * icon load by hand.
 */
Repeater {
    id: root
    required property string slot
    /// Column host, e.g. the vertical bar. Handed to the widgets as well
    property bool vertical: false
    /// Passed to the widget on load, for slots that hand it context
    property var initialProperties: null
    /// Host-side gate, on top of the widget's own `shown`
    property bool shown: true
    /// Gap after each item, along the layout
    property real spacing: 0

    model: WidgetCatalog.forSlot(root.slot, root.vertical ? "vertical" : "horizontal")
    delegate: Loader {
        required property var modelData
        Layout.alignment: root.vertical ? Qt.AlignHCenter : Qt.AlignVCenter
        Layout.rightMargin: root.vertical ? 0 : root.spacing
        Layout.bottomMargin: root.vertical ? root.spacing : 0
        visible: root.shown && (item?.shown ?? true)
        // setSource, not source: initialProperties only land through it. `vertical`
        // only when it is, so widgets built before it keep loading unchanged
        Component.onCompleted: setSource(modelData.resolve(modelData.slotPath(root.slot)),
            Object.assign(root.vertical ? { "vertical": true } : {}, root.initialProperties ?? {}))
        onStatusChanged: if (status === Loader.Error) ErrorReporter.report(modelData.widgetId, `${source} failed to load`)
    }
}
