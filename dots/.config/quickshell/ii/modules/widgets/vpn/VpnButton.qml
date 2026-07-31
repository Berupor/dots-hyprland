// Vpn button for the bar util group. Colored by status, opens VpnPopup on click.
//
// No tooltip on purpose: StyledToolTip is inverse-surface per Material spec, which
// made it the only light element in the bar.

import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.bar
import qs.modules.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

CircleUtilButton {
    id: vpnButton
    Layout.alignment: Qt.AlignVCenter
    toggled: menu.loadedVisible
    visible: VpnStatus.available

    // RippleButton's toggled background is colPrimary, nearly white in this theme.
    // Bar buttons that open panels use secondaryContainer instead.
    colBackgroundToggled: Appearance.colors.colSecondaryContainer
    colBackgroundToggledHover: Appearance.colors.colSecondaryContainerHover
    colRippleToggled: Appearance.colors.colSecondaryContainerActive

    onClicked: {
        if (menu.loadedVisible)
            menu.close();
        else
            menu.open();
    }

    // CircleUtilButton's default property `content` takes exactly one Item, so the
    // popup Loader lives inside the icon: as a second default child it would end up
    // outside the visual tree and the popup anchor would find no window.
    MaterialSymbol {
        horizontalAlignment: Qt.AlignHCenter
        fill: VpnStatus.connected ? 1 : 0
        text: VpnStatus.icon
        iconSize: Appearance.font.pixelSize.large
        color: vpnButton.toggled ? Appearance.colors.colOnSecondaryContainer : VpnStatus.connected ? Appearance.colors.colPrimary : Appearance.colors.colOnLayer2

        // Profile menu, anchored to the button rather than the icon
        Loader {
            id: menu
            active: false
            property bool loadedVisible: active && item && item.visible

            function open(): void {
                active = true;
            }
            function close(): void {
                if (item)
                    item.close();
            }

            sourceComponent: VpnPopup {
                Component.onCompleted: open()
                anchor {
                    window: vpnButton.QsWindow.window
                    item: vpnButton
                    gravity: Config.options.bar.vertical ? (Config.options.bar.bottom ? Edges.Left : Edges.Right) : (Config.options.bar.bottom ? Edges.Top : Edges.Bottom)
                    edges: Config.options.bar.vertical ? (Config.options.bar.bottom ? Edges.Left : Edges.Right) : (Config.options.bar.bottom ? Edges.Top : Edges.Bottom)
                }
                onDismissed: menu.active = false
            }
        }
    }
}
