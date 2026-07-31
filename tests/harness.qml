//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic

/**
 * Dev harness: render one widget slot from this tree in isolation, probe its
 * state, save a PNG, exit. Driven by env, see tests/widget-probe.sh.
 */
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.bar
import qs.modules.widgets
import qs.services
import QtQuick
import Quickshell

ShellRoot {
    id: root
    property string widgetId: Quickshell.env("QS_HARNESS_WIDGET") ?? ""
    property string slot: Quickshell.env("QS_HARNESS_SLOT") ?? ""
    property string file: Quickshell.env("QS_HARNESS_FILE") ?? ""
    property string out: Quickshell.env("QS_HARNESS_OUT") ?? "/tmp/harness.png"
    property var props: JSON.parse(Quickshell.env("QS_HARNESS_PROPS") ?? "{}")
    property var probe: JSON.parse(Quickshell.env("QS_HARNESS_PROBE") ?? "[]")
    property int settle: parseInt(Quickshell.env("QS_HARNESS_SETTLE") ?? "1200")
    property int itemW: parseInt(Quickshell.env("QS_HARNESS_IW") ?? "0")
    property int itemH: parseInt(Quickshell.env("QS_HARNESS_IH") ?? "0")

    readonly property var manifest: WidgetCatalog.widgets.find(w => w.widgetId === root.widgetId) ?? null
    readonly property string source: {
        // file:// so sibling types resolve without importing the widget's own module,
        // which is what manifest.resolve() ends up handing the hosts too
        if (root.file) return root.file.startsWith("/") ? `file://${root.file}` : Qt.resolvedUrl(root.file);
        if (!root.manifest) return "";
        const entry = root.manifest.slots[root.slot];
        if (!entry) return "";
        return root.manifest.resolve(entry.path ?? entry);
    }

    onSourceChanged: if (source) console.log(`[harness] source ${source}`)

    Timer {
        running: true
        interval: 3000
        onTriggered: if (!root.source) {
            console.log(`[harness] FAIL no slot: widget=${root.widgetId} slot=${root.slot} file=${root.file}`)
            console.log(`[harness] catalog ${WidgetCatalog.widgets.map(w => w.widgetId).join(",")}`)
            if (root.manifest) console.log(`[harness] slots ${Object.keys(root.manifest.slots).join(",")}`)
            console.log("[harness] done")
        }
    }

    FloatingWindow {
        id: win
        title: "qs-harness"
        implicitWidth: parseInt(Quickshell.env("QS_HARNESS_W") ?? "640")
        implicitHeight: parseInt(Quickshell.env("QS_HARNESS_H") ?? "360")
        color: Appearance.colors.colLayer0

        Loader {
            id: loader
            width: root.itemW > 0 ? root.itemW : (item?.implicitWidth > 0 ? item.implicitWidth : parent.width)
            height: root.itemH > 0 ? root.itemH : (item?.implicitHeight > 0 ? item.implicitHeight : parent.height)
            source: root.source

            onLoaded: {
                for (const key in root.props)
                    item[key] = root.props[key];
                grabTimer.start()
            }
            onStatusChanged: if (status === Loader.Error) {
                console.log(`[harness] FAIL load ${root.source}`)
                console.log("[harness] done")
            }
        }

        Timer {
            id: grabTimer
            interval: root.settle
            onTriggered: {
                for (const path of root.probe) {
                    let value = loader.item;
                    for (const part of path.split("."))
                        value = value?.[part];
                    console.log(`[harness] probe ${path} = ${JSON.stringify(value)}`)
                }
                console.log(`[harness] size ${loader.width}x${loader.height}`)
                loader.grabToImage(res => {
                    console.log(`[harness] png ${res.saveToFile(root.out) ? "ok" : "FAIL"} ${root.out}`)
                    console.log("[harness] done")
                })
            }
        }
    }
}
