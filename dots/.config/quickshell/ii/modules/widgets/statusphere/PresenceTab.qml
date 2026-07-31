pragma ComponentBehavior: Bound

import qs.services
import qs.modules.common
import qs.modules.widgets
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

// Who's around in the statusphere room: live presence, activity, now playing.
Item {
    id: root

    PagePlaceholder {
        shown: Statusphere.accountIds.length === 0
        icon: "groups"
        shape: MaterialShape.Shape.Ghostish
        descriptionHorizontalAlignment: Text.AlignHCenter
        description: Statusphere.placeholderText()
    }

    ColumnLayout {
        anchors {
            fill: parent
            margins: 4
        }
        spacing: 6
        visible: Statusphere.accountIds.length > 0

        StyledText {
            Layout.leftMargin: 6
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Appearance.colors.colSubtext
            text: Translation.tr("%1 of %2 online").arg(Statusphere.onlineCount).arg(Statusphere.memberCount)
        }

        StyledFlickable {
            id: flickable
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: column.implicitHeight
            clip: true

            ColumnLayout {
                id: column
                width: flickable.width
                spacing: 12

                Repeater {
                    model: Statusphere.accountIds
                    delegate: PresenceRow {}
                }
            }
        }
    }
}
