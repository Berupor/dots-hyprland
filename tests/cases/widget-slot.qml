//@ probe hello -x tests/fixtures/hello -g 320x120 -s 1500
/**
 * The two ways a host reaches a slot: WidgetSlot for the ones it loads, and
 * the catalog's own builders for the ones it hands to a layout or calls.
 */
import qs.modules.widgets
import QtQuick
import QtQuick.Layouts

Item {
    id: probe

    function checks() {
        const tabs = WidgetCatalog.itemsFor("sidebarLeftTab", probe);
        const claimed = WidgetCatalog.actionFor("regionAction", "hello", probe);
        if (claimed)
            claimed.perform("/tmp/shot.png", 1, 2, 3, 4);
        return [
            {
                "name": "one loader per widget in the slot",
                "got": plain.count,
                "want": 1
            },
            {
                "name": "the slot file loads",
                "got": plain.itemAt(0)?.status === Loader.Ready,
                "want": true
            },
            {
                "name": "the widget comes up whole",
                "got": plain.itemAt(0)?.item?.greeting ?? "",
                "want": "Hello"
            },
            {
                "name": "a widget nobody claims loads nothing",
                "got": empty.count,
                "want": 0
            },
            {
                "name": "spacing lands as a gap after the item",
                "got": spaced.implicitWidth - (spacedSlot.itemAt(0)?.implicitWidth ?? 0),
                "want": 12
            },
            {
                "name": "the host gate hides the item",
                "got": gated.itemAt(0)?.visible ?? true,
                "want": false
            },
            {
                "name": "a column host loads the widget drawing for it",
                "got": column.count,
                "want": 1
            },
            {
                "name": "the widget is told which way it is drawn",
                "got": column.itemAt(0)?.item?.vertical ?? false,
                "want": true
            },
            {
                "name": "there the gap goes under the item",
                "got": stacked.implicitHeight - (stackedSlot.itemAt(0)?.implicitHeight ?? 0),
                "want": 12
            },
            {
                "name": "a slot declared without orientations stays out of a column",
                "got": WidgetCatalog.forSlot("sidebarLeftTab", "vertical").length,
                "want": 0
            },
            {
                "name": "itemsFor builds one object per widget in the slot",
                "got": tabs.length,
                "want": 1
            },
            {
                "name": "the built object is the widget's own type",
                "got": tabs[0]?.greeting ?? "",
                "want": "Hello"
            },
            {
                "name": "itemsFor builds nothing for a slot nobody claims",
                "got": WidgetCatalog.itemsFor("sidebarRightTab", probe).length,
                "want": 0
            },
            {
                "name": "actionFor finds the widget claiming the name",
                "got": claimed?.lastRegion ?? "",
                "want": "/tmp/shot.png 1,2 3x4"
            },
            {
                "name": "an empty name takes the first one",
                "got": !!WidgetCatalog.actionFor("regionAction", "", probe),
                "want": true
            },
            {
                "name": "a name nobody answers to gets nothing",
                "got": WidgetCatalog.actionFor("regionAction", "nope", probe),
                "want": null
            }
        ];
    }

    RowLayout {
        WidgetSlot {
            id: plain
            slot: "barIndicator"
        }
    }

    RowLayout {
        WidgetSlot {
            id: empty
            slot: "barUtilButton"
        }
    }

    RowLayout {
        id: spaced
        WidgetSlot {
            id: spacedSlot
            slot: "barIndicator"
            spacing: 12
        }
    }

    RowLayout {
        WidgetSlot {
            id: gated
            slot: "barIndicator"
            shown: false
        }
    }

    ColumnLayout {
        WidgetSlot {
            id: column
            slot: "barIndicator"
            vertical: true
        }
    }

    ColumnLayout {
        id: stacked
        WidgetSlot {
            id: stackedSlot
            slot: "barIndicator"
            vertical: true
            spacing: 12
        }
    }
}
