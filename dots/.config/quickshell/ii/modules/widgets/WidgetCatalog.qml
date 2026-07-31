pragma Singleton
import Qt.labs.folderlistmodel
import Quickshell
import QtQuick

/**
 * Scans modules/widgets/<id>/Manifest.qml. See WidgetManifest for the contract.
 */
Singleton {
    id: root
    property list<QtObject> widgets: []

    function isEnabled(widgetId) {
        return (WidgetsStore.data.enabled ?? []).includes(widgetId)
    }

    function forSlot(slot) {
        return widgets.filter(w => w.slots[slot] !== undefined && w.available && isEnabled(w.widgetId))
    }

    function option(widgetId, key) {
        const stored = WidgetsStore.data.options?.[widgetId]?.[key]
        if (stored !== undefined) return stored
        const manifest = widgets.find(w => w.widgetId === widgetId)
        return manifest?.options.find(o => o.key === key)?.default
    }

    function scan() {
        const found = []
        for (let i = 0; i < folders.count; i++) {
            // Resolve against this file, not the scanned fileUrl: components loaded
            // from file:// urls can't import qs.* submodules
            const dir = Qt.resolvedUrl(folders.get(i, "fileName"))
            const component = Qt.createComponent(dir + "/Manifest.qml")
            if (component.status === Component.Error) {
                console.warn("[WidgetCatalog] " + component.errorString())
                continue
            }
            const manifest = component.createObject(root, { "dir": dir })
            if (manifest) found.push(manifest)
        }
        found.sort((a, b) => a.widgetId.localeCompare(b.widgetId))
        root.widgets = found
    }

    FolderListModel {
        id: folders
        folder: Qt.resolvedUrl(".")
        showDirs: true
        showFiles: false
        onStatusChanged: if (status === FolderListModel.Ready) root.scan()
    }
}
