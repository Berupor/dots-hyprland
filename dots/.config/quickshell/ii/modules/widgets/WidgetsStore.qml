pragma Singleton
import qs.modules.common
import Quickshell
import Quickshell.Io
import QtQuick

/**
 * Widget catalog state: enabled ids and per-widget options.
 */
Singleton {
    id: root
    property var data: ({ "enabled": [], "options": {} })

    function setEnabled(widgetId, on) {
        const enabled = (data.enabled ?? []).filter(x => x !== widgetId)
        if (on) enabled.push(widgetId)
        root.data = Object.assign({}, data, { "enabled": enabled })
        save()
    }

    function setOption(widgetId, key, value) {
        const options = Object.assign({}, data.options)
        options[widgetId] = Object.assign({}, options[widgetId], { [key]: value })
        root.data = Object.assign({}, data, { "options": options })
        save()
    }

    function save() {
        fileView.setText(JSON.stringify(root.data, null, 2))
    }

    FileView {
        id: fileView
        path: Qt.resolvedUrl(`${Directories.shellConfig}/widgets.json`)
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                root.data = JSON.parse(fileView.text())
            } catch (e) {
                console.warn("[WidgetsStore] Bad json: " + e)
            }
        }
        onLoadFailed: error => {
            if (error == FileViewError.FileNotFound) save()
        }
    }
}
