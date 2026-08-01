//@ probe hello -x tests/fixtures/hello -g 320x120 -s 1500
/**
 * WidgetSlot, the loader hosts put in a slot: one item per enabled widget,
 * the host gate on top of the widget's own, and the gap it asks for.
 */
import qs.modules.widgets
import QtQuick
import QtQuick.Layouts

Item {
    id: probe

    function checks() {
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
}
