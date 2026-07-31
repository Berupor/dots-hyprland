import qs.modules.widgets
import qs.services

WidgetManifest {
    widgetId: "statusphere"
    name: Translation.tr("Statusphere")
    description: Translation.tr("Who's around in your statusphere room")
    icon: "groups"
    available: Statusphere.available
    settingsPage: "StatusphereSettings.qml"
    slots: ({
        "barIndicator": "StatusphereIncognitoIndicator.qml",
        "sidebarLeftTab": { "name": Translation.tr("Room"), "icon": "groups", "path": "PresenceTab.qml" }
    })
}
