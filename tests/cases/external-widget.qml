//@ probe hello -x tests/fixtures/hello -o badge=false -g 320x80 -s 1500
/**
 * A widget installed outside the shell tree: the catalog finds it, its slot
 * loads by absolute file:// url and its own types and options come along.
 */
import qs.modules.widgets
import QtQuick

Item {
    id: probe

    readonly property var manifest: WidgetCatalog.widgets.find(w => w.widgetId === "hello") ?? null
    readonly property string slotPath: probe.manifest ? String(probe.manifest.resolve(probe.manifest.slots["barIndicator"])) : ""

    function checks() {
        return [
            {
                "name": "catalog picks the external widget up",
                "got": WidgetCatalog.widgets.map(w => w.widgetId).includes("hello"),
                "want": true
            },
            {
                "name": "it loads from the widget dir of the config",
                "got": String(probe.manifest?.dir ?? "").endsWith("/illogical-impulse/widgets/hello"),
                "want": true
            },
            {
                "name": "slot paths resolve inside it",
                "got": probe.slotPath.endsWith("/illogical-impulse/widgets/hello/HelloIndicator.qml"),
                "want": true
            },
            {
                "name": "bundled widgets still load",
                "got": WidgetCatalog.widgets.map(w => w.widgetId).includes("androidWebcam"),
                "want": true
            },
            {
                "name": "it reaches its slot",
                "got": WidgetCatalog.forSlot("barIndicator").map(w => w.widgetId),
                "want": ["hello"]
            },
            {
                "name": "the schema default is declared",
                "got": probe.manifest?.options[0]?.default ?? null,
                "want": true
            },
            {
                "name": "a stored option beats the default",
                "got": WidgetCatalog.option("hello", "badge"),
                "want": false
            },
            {
                "name": "the slot file loads",
                "got": loader.status === Loader.Ready,
                "want": true
            },
            {
                "name": "its own singleton resolves, qmldir and all",
                "got": loader.item?.greeting ?? "",
                "want": "Hello"
            },
            {
                "name": "its sibling type and design system imports render",
                "got": (loader.item?.implicitWidth ?? 0) > 0,
                "want": true
            }
        ];
    }

    Loader {
        id: loader
        anchors.centerIn: parent
        source: probe.slotPath
    }
}
