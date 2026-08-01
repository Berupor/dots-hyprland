//@ probe hello -x tests/fixtures/hello -g 560x220 -s 1500
/**
 * Catalog cards for an installed widget and a bundled one: only the installed
 * one is marked, and its marker says where it sits.
 */
import qs.modules.widgets
import QtQuick
import QtQuick.Layouts

Item {
    id: probe

    readonly property var installed: WidgetCatalog.widgets.find(w => w.widgetId === "hello") ?? null
    readonly property var bundled: WidgetCatalog.widgets.find(w => w.widgetId === "androidWebcam") ?? null

    function checks() {
        return [
            {
                "name": "the installed widget is marked external",
                "got": probe.installed?.external ?? null,
                "want": true
            },
            {
                "name": "a bundled widget is not",
                "got": probe.bundled?.external ?? null,
                "want": false
            },
            {
                // The probe runs on a throwaway XDG_CONFIG_HOME, so only the tail is stable
                "name": "the marker points at the widget dir",
                "got": (cards.itemAt(0)?.originText?.split("\n")[0] ?? "").replace(/^Installed in .*(\/illogical-impulse\/)/, "$1"),
                "want": "/illogical-impulse/widgets/hello"
            },
            {
                "name": "and carries author and version",
                "got": cards.itemAt(0)?.originText?.split("\n")[1] ?? "",
                "want": "tests · 1.0"
            },
            {
                "name": "cards render at full width",
                "got": (cards.itemAt(0)?.width ?? 0) === probe.width && (cards.itemAt(1)?.width ?? 0) === probe.width,
                "want": true
            }
        ];
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        Repeater {
            id: cards
            model: [probe.installed, probe.bundled].filter(m => m !== null)
            delegate: WidgetCard {
                required property var modelData
                manifest: modelData
            }
        }

        Item {
            Layout.fillHeight: true
        }
    }
}
