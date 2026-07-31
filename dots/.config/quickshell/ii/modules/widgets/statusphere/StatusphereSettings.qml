import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.widgets

ColumnLayout {

    ContentSubsection {
        title: Translation.tr("Incognito")

        ConfigSwitch {
            buttonIcon: "touch_app"
            text: Translation.tr('Hold your own row to hide')
            checked: Config.options.sidebar.statusphere.incognito.enable
            onCheckedChanged: {
                Config.options.sidebar.statusphere.incognito.enable = checked;
            }
            StyledToolTip {
                text: Translation.tr("Hold your avatar in the presence tab, slide onto how long, let go.\nHides what you have open; music keeps playing.\nWhat's hidden never leaves this machine, so it stays out of the server's history too")
            }
        }

        ConfigSwitch {
            buttonIcon: "toast"
            text: Translation.tr('Remind me in the bar')
            checked: WidgetCatalog.option("statusphere", "incognitoIndicator") ?? true
            onCheckedChanged: {
                WidgetsStore.setOption("statusphere", "incognitoIndicator", checked);
            }
            StyledToolTip {
                text: Translation.tr("An icon while you're hiding, so you don't stay dark for a week by accident.\nClick it to be visible again")
            }
        }
    }

    ContentSubsection {
        title: Translation.tr("Servers")

        ConfigSwitch {
            buttonIcon: "monitoring"
            text: Translation.tr('Metrics on the card')
            checked: Config.options.sidebar.statusphere.server.showMetrics
            onCheckedChanged: {
                Config.options.sidebar.statusphere.server.showMetrics = checked;
            }
            StyledToolTip {
                text: Translation.tr("A machine has no window title, so its card shows cpu, memory, disk and load instead.\nThe verdict next to the name comes from that machine's own ~/.config/statusphere/health.json")
            }
        }

        ConfigSpinBox {
            icon: "network_ping"
            text: Translation.tr("Reachability check (seconds)")
            value: Config.options.sidebar.statusphere.server.pingSeconds
            from: 15
            to: 600
            stepSize: 15
            onValueChanged: {
                Config.options.sidebar.statusphere.server.pingSeconds = value;
            }
            StyledToolTip {
                text: Translation.tr("A server card shows what its machine reports: cpu, memory, disk, load.\nThe agent can't report its own death, so the server is asked directly too")
            }
        }
    }

    ContentSubsection {
        title: Translation.tr("Photos")

        ConfigSwitch {
            buttonIcon: "check"
            text: Translation.tr('Friends\' shared photos')
            checked: Config.options.sidebar.statusphere.photo.enable
            onCheckedChanged: {
                Config.options.sidebar.statusphere.photo.enable = checked;
            }
            StyledToolTip {
                text: Translation.tr("Shows a room member's current shared photo below their row")
            }
        }

        ConfigSpinBox {
            enabled: Config.options.sidebar.statusphere.photo.enable
            icon: "compress"
            text: Translation.tr("Min photo height")
            value: Config.options.sidebar.statusphere.photo.minHeight
            from: 60
            to: 320
            stepSize: 20
            onValueChanged: {
                Config.options.sidebar.statusphere.photo.minHeight = value;
            }
        }

        ConfigSpinBox {
            enabled: Config.options.sidebar.statusphere.photo.enable
            icon: "expand"
            text: Translation.tr("Max photo height")
            value: Config.options.sidebar.statusphere.photo.maxHeight
            from: 120
            to: 640
            stepSize: 20
            onValueChanged: {
                Config.options.sidebar.statusphere.photo.maxHeight = value;
            }
        }

        ConfigSwitch {
            buttonIcon: "add_a_photo"
            text: Translation.tr('Share photos yourself')
            checked: Config.options.sidebar.statusphere.photo.share
            onCheckedChanged: {
                Config.options.sidebar.statusphere.photo.share = checked;
            }
            StyledToolTip {
                text: Translation.tr("Middle-click your own card for share actions.\nMiddle-drag in the region selector shares that region right away")
            }
        }
    }

    ContentSubsection {
        title: Translation.tr("Wallpaper card")

        ConfigRow {
            Layout.fillWidth: true

            ConfigSwitch {
                Layout.fillWidth: false
                buttonIcon: "check"
                text: Translation.tr("Enable")
                checked: Config.options.background.widgets.presence.enable
                onCheckedChanged: {
                    Config.options.background.widgets.presence.enable = checked;
                }
                StyledToolTip {
                    text: Translation.tr("Same rows as the left sidebar's presence tab, as a card on the wallpaper.\nNeeds the statusphere cli and a registered account")
                }
            }
            Item {
                Layout.fillWidth: true
            }
            ConfigSelectionArray {
                Layout.fillWidth: false
                currentValue: Config.options.background.widgets.presence.placementStrategy
                onSelected: newValue => {
                    Config.options.background.widgets.presence.placementStrategy = newValue;
                }
                options: [
                    {
                        displayName: Translation.tr("Draggable"),
                        icon: "drag_pan",
                        value: "free"
                    },
                    {
                        displayName: Translation.tr("Least busy"),
                        icon: "category",
                        value: "leastBusy"
                    },
                    {
                        displayName: Translation.tr("Most busy"),
                        icon: "shapes",
                        value: "mostBusy"
                    },
                ]
            }
        }

        ConfigSwitch {
            buttonIcon: "person_off"
            text: Translation.tr("Hide offline members")
            checked: Config.options.background.widgets.presence.hideOffline
            onCheckedChanged: {
                Config.options.background.widgets.presence.hideOffline = checked;
            }
        }

        ConfigSpinBox {
            icon: "fit_width"
            text: Translation.tr("Width")
            value: Config.options.background.widgets.presence.width
            from: 200
            to: 800
            stepSize: 20
            onValueChanged: {
                Config.options.background.widgets.presence.width = value;
            }
        }

        ConfigSpinBox {
            icon: "format_list_numbered"
            text: Translation.tr("Max rows (0 for everyone)")
            value: Config.options.background.widgets.presence.maxRows
            from: 0
            to: 20
            stepSize: 1
            onValueChanged: {
                Config.options.background.widgets.presence.maxRows = value;
            }
        }
    }
}
