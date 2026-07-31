import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.widgets

ColumnLayout {

    function setOption(key, value) {
        WidgetsStore.setOption("statusphere", key, value);
    }

    ContentSubsection {
        title: Translation.tr("Incognito")

        ConfigSwitch {
            buttonIcon: "touch_app"
            text: Translation.tr('Hold your own row to hide')
            checked: Statusphere.opt("incognito")
            onClicked: setOption("incognito", !checked)
            StyledToolTip {
                text: Translation.tr("Hold your avatar in the presence tab, slide onto how long, let go.\nHides what you have open; music keeps playing.\nWhat's hidden never leaves this machine, so it stays out of the server's history too")
            }
        }

        ConfigSwitch {
            buttonIcon: "toast"
            text: Translation.tr('Remind me in the bar')
            checked: Statusphere.opt("incognitoIndicator")
            onClicked: setOption("incognitoIndicator", !checked)
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
            checked: Statusphere.opt("serverMetrics")
            onClicked: setOption("serverMetrics", !checked)
            StyledToolTip {
                text: Translation.tr("A machine has no window title, so its card shows cpu, memory, disk and load instead.\nThe verdict next to the name comes from that machine's own ~/.config/statusphere/health.json")
            }
        }

        ConfigSpinBox {
            icon: "network_ping"
            text: Translation.tr("Reachability check (seconds)")
            value: Statusphere.opt("serverPingSeconds")
            from: 15
            to: 600
            stepSize: 15
            onValueChanged: {
                setOption("serverPingSeconds", value);
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
            checked: Statusphere.opt("photos")
            onClicked: setOption("photos", !checked)
            StyledToolTip {
                text: Translation.tr("Shows a room member's current shared photo below their row")
            }
        }

        ConfigSpinBox {
            enabled: Statusphere.opt("photos")
            icon: "compress"
            text: Translation.tr("Min photo height")
            value: Statusphere.opt("photoMinHeight")
            from: 60
            to: 320
            stepSize: 20
            onValueChanged: {
                setOption("photoMinHeight", value);
            }
        }

        ConfigSpinBox {
            enabled: Statusphere.opt("photos")
            icon: "expand"
            text: Translation.tr("Max photo height")
            value: Statusphere.opt("photoMaxHeight")
            from: 120
            to: 640
            stepSize: 20
            onValueChanged: {
                setOption("photoMaxHeight", value);
            }
        }

        ConfigSwitch {
            buttonIcon: "add_a_photo"
            text: Translation.tr('Share photos yourself')
            checked: Statusphere.opt("photoShare")
            onClicked: setOption("photoShare", !checked)
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
                checked: Statusphere.opt("wallpaperCard")
                onClicked: setOption("wallpaperCard", !checked)
                StyledToolTip {
                    text: Translation.tr("Same rows as the left sidebar's presence tab, as a card on the wallpaper.\nNeeds the statusphere cli and a registered account")
                }
            }
            Item {
                Layout.fillWidth: true
            }
            ConfigSelectionArray {
                Layout.fillWidth: false
                currentValue: Statusphere.opt("wallpaperPlacement")
                onSelected: newValue => {
                    setOption("wallpaperPlacement", newValue);
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
            checked: Statusphere.opt("wallpaperHideOffline")
            onClicked: setOption("wallpaperHideOffline", !checked)
        }

        ConfigSpinBox {
            icon: "fit_width"
            text: Translation.tr("Width")
            value: Statusphere.opt("wallpaperWidth")
            from: 200
            to: 800
            stepSize: 20
            onValueChanged: {
                setOption("wallpaperWidth", value);
            }
        }

        ConfigSpinBox {
            icon: "format_list_numbered"
            text: Translation.tr("Max rows (0 for everyone)")
            value: Statusphere.opt("wallpaperMaxRows")
            from: 0
            to: 20
            stepSize: 1
            onValueChanged: {
                setOption("wallpaperMaxRows", value);
            }
        }
    }
}
