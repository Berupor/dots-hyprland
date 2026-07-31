//@ probe -g 320x260
/**
 * Nav rail active indicator: geometry per tab, collapsed and expanded.
 * A Repeater sits among the buttons in children, so tab index != child index.
 */
import qs.modules.common
import qs.modules.common.widgets
import QtQuick

Item {
    id: probe

    function checks() {
        const result = [];
        // Collapsed indicator: 56x32 pill on every tab, stepping by item height
        for (let i = 0; i < 3; i++) {
            const indicator = rails.itemAt(i)?.children[0];
            result.push({
                "name": `collapsed indicator width, tab ${i}`,
                "got": indicator?.width ?? -1,
                "want": 56
            }, {
                "name": `collapsed indicator height, tab ${i}`,
                "got": indicator?.height ?? -1,
                "want": 32
            }, {
                "name": `collapsed indicator offset, tab ${i}`,
                "got": indicator?.y ?? -1,
                "want": 56 * i + 12
            });
        }
        const collapsed = rails.itemAt(2);
        result.push({
            "name": "buttons skip the Repeater",
            "got": collapsed?.buttons?.length ?? -1,
            "want": 3
        }, {
            "name": "currentButton is the tab at currentIndex",
            "got": collapsed?.currentButton?.buttonText ?? "",
            "want": "Tab 2"
        }, {
            "name": "expanded indicator is as wide as its button",
            "got": expanded.children[0].width,
            "want": expanded.buttons?.[2]?.visualWidth ?? -1
        }, {
            "name": "expanded indicator is as tall as its button",
            "got": expanded.children[0].height,
            "want": expanded.buttons?.[2]?.baseSize ?? -1
        });
        return result;
    }

    component Rail: NavigationRailTabArray {
        id: rail
        Repeater {
            model: 3
            NavigationRailButton {
                required property int index
                expanded: rail.expanded
                toggled: rail.currentIndex === index
                buttonText: `Tab ${index}`
                buttonIcon: "star"
                showToggledHighlight: false
            }
        }
    }

    Row {
        anchors.fill: parent
        Repeater {
            id: rails
            model: 3
            Rail {
                required property int index
                currentIndex: index
            }
        }
        Rail {
            id: expanded
            currentIndex: 2
            expanded: true
        }
    }
}
