pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.background.widgets
import qs.modules.ii.sidebarLeft.presence

// Same room presence rows as the left sidebar, as a card on the wallpaper.
AbstractBackgroundWidget {
    id: root

    configEntryName: "presence"

    readonly property var shownAccountIds: {
        const ids = Statusphere.accountIds.filter(id => !root.configEntry.hideOffline || !Statusphere.accountsById[id].offline);
        return root.configEntry.maxRows > 0 ? ids.slice(0, root.configEntry.maxRows) : ids;
    }

    implicitWidth: root.configEntry.width
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
