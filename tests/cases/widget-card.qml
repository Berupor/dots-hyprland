//@ probe hello -x tests/fixtures/hello -g 560x760 -s 1500
/**
 * Catalog cards for an installed widget, a bundled one and one built for a shell
 * that isn't this one: only the installed one is marked, only the last one is barred.
 */
import qs.modules.widgets
import QtQuick
import QtQuick.Layouts

Item {
    id: probe

    readonly property var installed: WidgetCatalog.widgets.find(w => w.widgetId === "hello") ?? null
    readonly property var bundled: WidgetCatalog.widgets.find(w => w.widgetId === "androidWebcam") ?? null

    WidgetManifest {
        id: future
        widgetId: "future"
        name: "Future"
        description: "Asks for a contract this shell does not have"
        minShellVersion: "9.0"
    }

    // external so the card opens without the store, see canExpand
    WidgetManifest {
        id: everyOption
        widgetId: "everyOption"
        name: "Every option"
        description: "One control per option type"
        external: true
        options: [
            {
                key: "sw",
                type: "switch",
                label: "Switch",
                icon: "toggle_on",
                default: true
            },
            {
                key: "num",
                type: "spinBox",
                label: "Number",
                icon: "timer",
                min: 0,
                max: 10,
                default: 3
            },
            {
                key: "text",
                type: "textField",
                label: "Text",
                icon: "edit",
                placeholder: "Empty",
                default: ""
            }
        ]
    }

    WidgetManifest {
        id: noOption
        widgetId: "noOption"
        name: "No options"
        description: "Nothing to draw, same card otherwise"
        external: true
    }

    /// A contract version relative to this shell's, so a bump does not rewrite the checks
    function contract(dMajor, dMinor) {
        const parts = WidgetCatalog.shellVersion.split(".").map(Number);
        return `${parts[0] + dMajor}.${parts[1] + dMinor}`;
    }

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
            },
            {
                // Update and remove live in the body, and a widget is usually off when removed
                "name": "an installed widget opens while switched off",
                "got": (cards.itemAt(0)?.widgetEnabled ?? true) === false && (cards.itemAt(0)?.bodyShown ?? false),
                "want": true
            },
            {
                "name": "a bundled one does not",
                "got": cards.itemAt(1)?.canExpand ?? true,
                "want": false
            },
            {
                "name": "dotted versions compare by number",
                "got": [["1.10", "1.9"], ["1.0", "1.0.0"], ["1.2", "2.0"]].map(p => WidgetCatalog.compareVersions(p[0], p[1])),
                "want": [1, 0, -1]
            },
            {
                "name": "the contract runs its own major, up to its own version",
                "got": ["1.0", probe.contract(0, 0), probe.contract(-1, 0), probe.contract(0, 1), probe.contract(1, 0)].map(v => WidgetCatalog.supports(v)),
                "want": [true, true, false, false, false]
            },
            {
                // Its deps are fine, the contract is not, and available is the author's to override
                "name": "a widget from another contract is not usable",
                "got": [future.available, future.supported, future.usable],
                "want": [true, false, false]
            },
            {
                "name": "and its card says which contract it wanted",
                "got": cards.itemAt(2)?.statusText ?? "",
                "want": `Built for shell 9.0, this is ${WidgetCatalog.shellVersion}`
            },
            {
                "name": "a widget that runs shows what it does instead",
                "got": cards.itemAt(0)?.statusText ?? "",
                "want": probe.installed?.description ?? ""
            },
            {
                // A type the card cannot draw loads nothing, so the body stays that much shorter
                "name": "every option type draws a control",
                "got": (cards.itemAt(3)?.implicitHeight ?? 0) - (cards.itemAt(4)?.implicitHeight ?? 0) > 100,
                "want": true
            }
        ];
    }

    Timer { // The probe enables what it probes, and removal is a thing you do to an off widget
        running: true
        interval: 300
        onTriggered: {
            WidgetsStore.setEnabled("hello", false);
            cards.itemAt(0).expanded = true;
            cards.itemAt(3).expanded = true;
            cards.itemAt(4).expanded = true;
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        Repeater {
            id: cards
            model: [probe.installed, probe.bundled, future, everyOption, noOption].filter(m => m !== null)
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
