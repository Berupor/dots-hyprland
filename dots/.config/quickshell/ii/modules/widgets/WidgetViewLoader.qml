import QtQuick
import qs.modules.widgets

/**
 * Widget-provided replacement for a host view. Inactive without one, and drops
 * a view that fails to load so the built-in one comes back.
 */
Loader {
    id: root
    required property string slot
    readonly property var view: WidgetCatalog.viewFor(root.slot)

    active: !!root.view
    source: root.view ? root.view.resolve(root.view.slotPath(root.slot)) : ""
    onStatusChanged: if (status === Loader.Error) WidgetCatalog.dropView(root.view.widgetId, root.source)
}
