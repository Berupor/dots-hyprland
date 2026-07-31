import QtQuick
import Quickshell
import Quickshell.Io

/**
 * A catalog widget. To add one:
 * 1. Create modules/widgets/<id>/ with Manifest.qml and slot files.
 *    Service singletons go flat into modules/widgets/ (dynamically loaded
 *    files resolve `import qs.modules.widgets`, but not subdir modules)
 * 2. Slot paths are relative to the widget dir; barIndicator files expose `shown`
 * 3. Declare options with defaults, read them via WidgetCatalog.option(id, key)
 * 4. List required binaries in `dependencies`
 * Build from the design system only: Appearance.* colors and fonts,
 * MaterialSymbol, widgets from modules/common/widgets/.
 */
QtObject {
    id: root
    required property string widgetId
    property string name
    property string description
    property string icon: "widgets"
    property string version: "1.0"
    property string author: ""
    property list<string> dependencies: []
    property var slots: ({})
    property var options: []
    property string settingsPage: ""
    property url dir // Set by WidgetCatalog

    property list<string> depsMissing: []
    property bool depsChecked: dependencies.length === 0
    property bool available: depsChecked && depsMissing.length === 0

    function resolve(rel) {
        return `${dir}/${rel}`
    }

    property Process depsCheck: Process {
        running: root.dependencies.length > 0
        command: ["bash", "-c", "for c in " + root.dependencies.join(" ") + "; do command -v \"$c\" >/dev/null || echo \"$c\"; done"]
        stdout: StdioCollector {
            id: collector
            onStreamFinished: {
                root.depsMissing = collector.text.trim() ? collector.text.trim().split("\n") : []
                root.depsChecked = true
            }
        }
    }
}
