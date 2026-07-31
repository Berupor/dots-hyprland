pragma ComponentBehavior: Bound

// Vpn click menu: profile list (click to connect or switch, click the active one to
// disconnect), active tunnel details and an entry opening the vpn tui.
//
// Follows end-4 idioms: window frame as in SysTrayMenu.qml, StyledPopupHeaderRow and
// StyledPopupValueRow for the header and detail rows, checkmark on the active entry
// as in the wifi list.

import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.bar
import qs.modules.widgets
import qs.services
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

PopupWindow {
    id: root

    signal dismissed

    color: "transparent"
    property real padding: Appearance.sizes.elevationMargin

    // Profile names are short ("work", "home"), so a minimum width keeps the menu
    // from collapsing into a strip under the header
    readonly property real minContentWidth: 200

    implicitWidth: popupBackground.implicitWidth + root.padding * 2
    implicitHeight: popupBackground.implicitHeight + root.padding * 2

    function open(): void {
        root.visible = true;
    }
    function close(): void {
        root.visible = false;
        root.dismissed();
    }

    // Dismiss on click outside the popup. Grab only the popup window itself
    // (matches BarPopup): the click that opens the menu finishes before the grab
    // arms, so it won't self-close; clicks inside the popup stay inside the grab.
    HyprlandFocusGrab {
        id: focusGrab
        active: root.visible
        windows: [root]
        onCleared: root.close()
    }

    StyledRectangularShadow {
        target: popupBackground
    }

    Rectangle {
        id: popupBackground
        readonly property real padding: 4

        // Shared by header, rows and details so the icon column stays on one vertical
        readonly property real contentPadding: 12

        anchors {
            left: parent.left
            right: parent.right
            top: Config.options.bar.vertical ? undefined : Config.options.bar.bottom ? undefined : parent.top
            bottom: Config.options.bar.vertical ? undefined : Config.options.bar.bottom ? parent.bottom : undefined
            verticalCenter: Config.options.bar.vertical ? parent.verticalCenter : undefined
            margins: root.padding
        }
        implicitWidth: Math.max(root.minContentWidth, contentColumn.implicitWidth + padding * 2)
        implicitHeight: contentColumn.implicitHeight + padding * 2
        // Same background and radius as the bar's own popups: m3surfaceContainer is opaque,
        // while colLayer0 gave a nearly white backdrop
        color: Appearance.m3colors.m3surfaceContainer
        radius: Appearance.rounding.small
        border.width: 1
        border.color: Appearance.colors.colLayer0Border
        clip: true

        opacity: 0
        Component.onCompleted: opacity = 1
        Behavior on opacity {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }
        Behavior on implicitWidth {
            animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
        }
        Behavior on implicitHeight {
            animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
        }

        // Section separator, as in SysTrayMenu
        component Separator: Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: Appearance.colors.colSubtext
            Layout.topMargin: 4
            Layout.bottomMargin: 4
        }

        // Clickable row: geometry and radius as SysTrayMenu entries
        component MenuRow: RippleButton {
            readonly property real horizontalMargin: popupBackground.contentPadding
            horizontalPadding: horizontalMargin
            buttonRadius: popupBackground.radius - popupBackground.padding
            implicitWidth: contentItem.implicitWidth + horizontalPadding * 2
            implicitHeight: 36
            Layout.fillWidth: true
        }

        ColumnLayout {
            id: contentColumn
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: popupBackground.padding
            }
            spacing: 0

            StyledPopupHeaderRow {
                Layout.leftMargin: popupBackground.contentPadding
                Layout.rightMargin: popupBackground.contentPadding
                Layout.topMargin: 6
                Layout.bottomMargin: 2
                icon: VpnStatus.icon
                label: Translation.tr("VPN")
            }

            Separator {}

            // Empty list: don't leave two separators in a row
            StyledText {
                visible: VpnStatus.profiles.length === 0
                Layout.fillWidth: true
                Layout.leftMargin: popupBackground.contentPadding
                Layout.rightMargin: popupBackground.contentPadding
                Layout.topMargin: 6
                Layout.bottomMargin: 6
                text: Translation.tr("No profiles")
                color: Appearance.colors.colSubtext
            }

            // Profiles
            Repeater {
                model: VpnStatus.profiles
                delegate: MenuRow {
                    id: profileRow
                    required property var modelData
                    readonly property bool isActive: modelData.active === true

                    releaseAction: () => {
                        if (profileRow.isActive)
                            VpnStatus.disconnect(profileRow.modelData.name);
                        else
                            VpnStatus.connect(profileRow.modelData.name);
                        root.close();
                    }

                    contentItem: RowLayout {
                        anchors {
                            verticalCenter: parent.verticalCenter
                            left: parent.left
                            right: parent.right
                            leftMargin: profileRow.horizontalMargin
                            rightMargin: profileRow.horizontalMargin
                        }
                        spacing: 8

                        MaterialSymbol {
                            text: profileRow.isActive ? "vpn_lock" : "vpn_key"
                            fill: profileRow.isActive ? 1 : 0
                            iconSize: Appearance.font.pixelSize.large
                            color: profileRow.isActive ? Appearance.colors.colPrimary : Appearance.colors.colOnSurfaceVariant
                        }
                        StyledText {
                            Layout.fillWidth: true
                            text: profileRow.modelData.name
                            elide: Text.ElideRight
                            textFormat: Text.PlainText
                            color: profileRow.isActive ? Appearance.colors.colPrimary : Appearance.colors.colOnSurfaceVariant
                        }
                        // Checkmark on the active profile, as the active wifi network. On hover it turns
                        // into disconnect, since clicking the active profile drops the tunnel.
                        MaterialSymbol {
                            visible: profileRow.isActive
                            text: profileRow.hovered ? "link_off" : "check"
                            iconSize: Appearance.font.pixelSize.large
                            color: Appearance.colors.colPrimary
                        }
                    }
                }
            }

            // Active tunnel details
            ColumnLayout {
                Layout.fillWidth: true
                visible: VpnStatus.connected
                spacing: 4

                Separator {}

                StyledPopupValueRow {
                    Layout.fillWidth: true
                    Layout.leftMargin: popupBackground.contentPadding
                    Layout.rightMargin: popupBackground.contentPadding
                    visible: VpnStatus.vpnIp !== ""
                    icon: "lan"
                    label: Translation.tr("Address:")
                    value: VpnStatus.vpnIp
                }

                StyledPopupValueRow {
                    Layout.fillWidth: true
                    Layout.leftMargin: popupBackground.contentPadding
                    Layout.rightMargin: popupBackground.contentPadding
                    Layout.bottomMargin: 2
                    visible: VpnStatus.mode !== ""
                    icon: "alt_route"
                    label: Translation.tr("Routing:")
                    value: VpnStatus.mode === "split" ? `${Translation.tr("Split")} • ${VpnStatus.routes}` : VpnStatus.mode === "full" ? Translation.tr("Full tunnel") : VpnStatus.mode
                }
            }

            Separator {}

            // Open the full tui manager
            MenuRow {
                id: managerRow
                releaseAction: () => {
                    Quickshell.execDetached(["bash", "-c", `${Config.options.apps.terminal} -e $HOME/.local/bin/vpn`]);
                    root.close();
                }
                contentItem: RowLayout {
                    anchors {
                        verticalCenter: parent.verticalCenter
                        left: parent.left
                        right: parent.right
                        leftMargin: managerRow.horizontalMargin
                        rightMargin: managerRow.horizontalMargin
                    }
                    spacing: 8
                    MaterialSymbol {
                        text: "tune"
                        iconSize: Appearance.font.pixelSize.large
                        color: Appearance.colors.colOnSurfaceVariant
                    }
                    StyledText {
                        Layout.fillWidth: true
                        text: Translation.tr("Open manager…")
                        color: Appearance.colors.colOnSurfaceVariant
                    }
                }
            }
        }
    }
}
