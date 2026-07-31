import qs.modules.widgets
import qs.services

WidgetManifest {
    widgetId: "statusphere"
    name: Translation.tr("Statusphere")
    description: Translation.tr("Who's around in your statusphere room")
    icon: "groups"
    available: Statusphere.available
    settingsPage: "StatusphereSettings.qml"
    options: [ // Values only, StatusphereSettings draws them
        { "key": "incognito", "default": true },
        { "key": "incognitoIndicator", "default": true },
        { "key": "serverMetrics", "default": true },
        { "key": "serverPingSeconds", "default": 60 },
        { "key": "photos", "default": true },
        { "key": "photoMinHeight", "default": 100 },
        { "key": "photoMaxHeight", "default": 320 },
        { "key": "photoShare", "default": true },
        { "key": "wallpaperCard", "default": false },
        { "key": "wallpaperPlacement", "default": "free" },
        { "key": "wallpaperX", "default": 100 },
        { "key": "wallpaperY", "default": 500 },
        { "key": "wallpaperWidth", "default": 360 },
        { "key": "wallpaperHideOffline", "default": false },
        { "key": "wallpaperMaxRows", "default": 0 }
    ]
    slots: ({
        "barIndicator": "StatusphereIncognitoIndicator.qml",
        "sidebarLeftTab": { "name": Translation.tr("Room"), "icon": "groups", "path": "PresenceTab.qml" },
        "backgroundWidget": "PresenceBackgroundWidget.qml",
        "regionAction": { "name": "share", "path": "ShareRegionAction.qml" }
    })
}
