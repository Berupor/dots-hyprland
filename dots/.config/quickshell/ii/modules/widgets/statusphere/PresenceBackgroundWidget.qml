pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs
import qs.services
import qs.modules.common
import qs.modules.widgets
import qs.modules.common.widgets
import qs.modules.ii.background.widgets

// Same room presence rows as the left sidebar, as a card on the wallpaper.
AbstractBackgroundWidget {
    id: root

    configEntryName: "presence"
    // Placement comes from the widget store, not from Config
    configEntry: QtObject {
        readonly property string placementStrategy: Statusphere.opt("wallpaperPlacement")
        readonly property real x: Statusphere.opt("wallpaperX")
        readonly property real y: Statusphere.opt("wallpaperY")
    }
    onReleased: { // Store writes only on drop, a binding back into the store would loop
        root.targetX = root.x;
        root.targetY = root.y;
        WidgetsStore.setOption("statusphere", "wallpaperX", root.x);
        WidgetsStore.setOption("statusphere", "wallpaperY", root.y);
    }

    readonly property bool shown: Statusphere.opt("wallpaperCard") && Statusphere.available
    readonly property var shownAccountIds: {
        if (!root.shown)
            return [];
        const maxRows = Statusphere.opt("wallpaperMaxRows");
        const ids = Statusphere.accountIds.filter(id => !Statusphere.opt("wallpaperHideOffline") || !Statusphere.accountsById[id].offline);
        return maxRows > 0 ? ids.slice(0, maxRows) : ids;
    }

    // The host keeps the card loaded, so switching it off is opacity, not unloading
    opacity: (root.shown && !(GlobalStates.screenLocked && !root.visibleWhenLocked)) ? 1 : 0
    implicitWidth: Statusphere.opt("wallpaperWidth")
    implicitHeight: card.implicitHeight

    StyledDropShadow {
        target: card
    }

    Rectangle {
        id: card
        anchors.fill: parent
        implicitHeight: column.implicitHeight + 24
        radius: Appearance.rounding.large
        color: Appearance.colors.colLayer0

        Behavior on implicitHeight {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }

        ColumnLayout {
            id: column
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 12
            }
            spacing: 8

            StyledText {
                Layout.leftMargin: 6
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colSubtext
                text: Translation.tr("%1 of %2 online").arg(Statusphere.onlineCount).arg(Statusphere.memberCount)
            }

            Repeater {
                model: root.shownAccountIds
                delegate: PresenceRow {}
            }
        }
    }
}
