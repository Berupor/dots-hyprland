pragma Singleton
import qs.modules.common
import Qt.labs.folderlistmodel
import Quickshell
import QtQuick

/**
 * Scans modules/widgets/<id>/Manifest.qml. See WidgetManifest for the contract.
 */
Singleton {
    id: root
    property list<QtObject> widgets: []
    property list<string> brokenViews: []
    readonly property string externalDir: `${Directories.shellConfig}/widgets`

    function isEnabled(widgetId) {
        return (WidgetsStore.data.enabled ?? []).includes(widgetId)
    }

    function forSlot(slot) {
        return widgets.filter(w => w.slots[slot] !== undefined && w.available && isEnabled(w.widgetId))
    }

    /// Widget replacing a host view, null when the built-in one stands
    function viewFor(slot) {
        return root.forSlot(slot).filter(w => !root.brokenViews.includes(w.widgetId))[0] ?? null
    }

    // A view that won't load can't be switched off from itself
    function dropView(widgetId, url) {
        ErrorReporter.report(widgetId, `${url} failed to load`)
        root.brokenViews = root.brokenViews.concat([widgetId])
    }

    function option(widgetId, key) {
        return widgets.find(w => w.widgetId === widgetId)?.optionValue(key)
    }

    function scan() {
        const found = []
        const add = (name, dir) => {
            const component = Qt.createComponent(`${dir}/Manifest.qml`)
            if (component.status === Component.Error) {
                ErrorReporter.report(name, component.errorString())
                return
            }
            const manifest = component.createObject(root, { "dir": dir })
            if (!manifest) return
            if (found.some(w => w.widgetId === manifest.widgetId)) {
                ErrorReporter.report(name, `duplicate widget id ${manifest.widgetId}`)
                return
            }
            found.push(manifest)
        }
        for (let i = 0; i < folders.count; i++)
            // Resolve against this file, not the scanned fileUrl: bundled widgets
            // import their own qs.modules.widgets.<id> module, which only the qs: scheme has
            add(folders.get(i, "fileName"), String(Qt.resolvedUrl(folders.get(i, "fileName"))))
        for (let i = 0; i < external.count; i++) {
            // A folder that does not exist yet makes the model list $HOME instead
            if (!String(external.get(i, "filePath")).startsWith(root.externalDir)) break
            add(external.get(i, "fileName"), String(external.get(i, "fileUrl")))
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

    /// Installed widgets, outside the shell tree so the installer's rsync can't wipe them
    FolderListModel {
        id: external
        folder: Qt.resolvedUrl(root.externalDir)
        showDirs: true
        showFiles: false
        onStatusChanged: if (status === FolderListModel.Ready) root.scan()
    }

    Component.onCompleted: Quickshell.execDetached(["mkdir", "-p", root.externalDir])
}
