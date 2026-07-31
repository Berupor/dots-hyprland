// Window frame for the vpn menu, contents in VpnMenu.qml. Frame as in SysTrayMenu.qml,
// dismissal as in BarPopup.

import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import Quickshell

PopupWindow {
    id: root

    signal dismissed

    // Loaded only while open, so nothing toggles this
    visible: true
    color: "transparent"
    property real padding: Appearance.sizes.elevationMargin

    implicitWidth: popupBackground.implicitWidth + root.padding * 2
    implicitHeight: popupBackground.implicitHeight + root.padding * 2

    function close(): void {
        root.dismissed();
    }

    // Dismiss on click outside through the shared grab: a second HyprlandFocusGrab
    // next to the shell's own one never fires. The bar is registered persistent
    // there, so clicking the button stays the button's own toggle.
    Component.onCompleted: GlobalFocusGrab.addDismissable(root)
    Component.onDestruction: GlobalFocusGrab.removeDismissable(root)

    Connections {
        target: GlobalFocusGrab
        function onDismissed(): void {
            root.close();
        }
    }

    StyledRectangularShadow {
        target: popupBackground
    }

    Rectangle {
        id: popupBackground

        anchors {
            left: parent.left
            right: parent.right
            top: Config.options.bar.vertical ? undefined : Config.options.bar.bottom ? undefined : parent.top
            bottom: Config.options.bar.vertical ? undefined : Config.options.bar.bottom ? parent.bottom : undefined
            verticalCenter: Config.options.bar.vertical ? parent.verticalCenter : undefined
            margins: root.padding
        }
        implicitWidth: menu.implicitWidth
        implicitHeight: menu.implicitHeight
        // m3surfaceContainer is opaque, while colLayer0 gave a nearly white backdrop
        color: Appearance.m3colors.m3surfaceContainer
        radius: Appearance.rounding.normal
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

        VpnMenu {
            id: menu
            anchors.fill: parent
            onRequestClose: root.close()
        }
    }
}
