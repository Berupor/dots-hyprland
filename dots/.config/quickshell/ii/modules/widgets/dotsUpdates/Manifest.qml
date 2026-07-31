import qs.modules.widgets
import qs.services

WidgetManifest {
    widgetId: "dotsUpdates"
    name: Translation.tr("Dots updates")
    description: Translation.tr("New commits in the dots checkout, pulled from the bar")
    icon: "system_update"
    dependencies: ["git"]
    settingsPage: "DotsUpdatesSettings.qml"
    options: [
        {
            "key": "checkMinutes",
            "type": "spinBox",
            "icon": "schedule",
            "label": Translation.tr("Check every (minutes)"),
            "default": 60,
            "min": 5,
            "max": 720,
            "step": 5
        },
        {
            "key": "notify",
            "type": "switch",
            "icon": "notifications",
            "label": Translation.tr("Notify when updates show up"),
            "default": false
        },
        {
            "key": "alwaysShow",
            "type": "switch",
            "icon": "toolbar",
            "label": Translation.tr("Keep the bar icon while up to date"),
            "default": false
        },
        {
            "key": "repoPath",
            "default": "~/Projects/dots-hyprland"
        }, // Drawn by the settings page
        // Notification state: reminded once a day per sha, never again once declined
        {
            "key": "notifiedSha",
            "default": ""
        },
        {
            "key": "notifiedAt",
            "default": 0
        },
        {
            "key": "dismissedSha",
            "default": ""
        }
    ]
    slots: ({
            "barIndicator": "UpdatesIndicator.qml"
        })
}
