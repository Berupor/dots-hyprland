//@ probe -g 100x40
/**
 * WidgetCatalog.slotProblems: unknown slots and missing required fields.
 */
import qs.modules.widgets
import QtQuick

Item {
    id: probe

    WidgetManifest {
        id: clean
        widgetId: "clean"
        name: "Clean"
        description: "Every field a slot needs"
        slots: ({
            "barIndicator": "BarIndicator.qml",
            "sidebarLeftTab": { "path": "Tab.qml", "name": "Clean", "icon": "check" },
            "regionAction": { "path": "Action.qml", "name": "clean" }
        })
    }

    WidgetManifest {
        id: broken
        widgetId: "broken"
        name: "Broken"
        description: "One of everything that can go wrong"
        slots: ({
            "barIndicator": "BarIndicator.qml",
            "madeUp": "Nothing.qml",
            "regionAction": "Action.qml",
            "sidebarLeftTab": { "path": "Tab.qml", "name": "Broken" }
        })
    }

    function checks() {
        return [
            {
                "name": "a slot with every required field has no problems",
                "got": WidgetCatalog.slotProblems(clean),
                "want": []
            },
            {
                "name": "a bare path with no required fields is fine",
                "got": WidgetCatalog.slotProblems(clean).some(p => p.includes("barIndicator")),
                "want": false
            },
            {
                "name": "an unknown slot is flagged",
                "got": WidgetCatalog.slotProblems(broken).some(p => p === 'unknown slot "madeUp"'),
                "want": true
            },
            {
                "name": "a bare path where fields are required is flagged",
                "got": WidgetCatalog.slotProblems(broken).some(p => p.includes("regionAction") && p.includes("bare path")),
                "want": true
            },
            {
                "name": "a missing required field is flagged",
                "got": WidgetCatalog.slotProblems(broken).some(p => p === 'slot "sidebarLeftTab" missing required field "icon"'),
                "want": true
            },
            {
                "name": "broken has exactly the three problems above",
                "got": WidgetCatalog.slotProblems(broken).length,
                "want": 3
            }
        ];
    }
}
