pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.widgets
import qs.modules.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell

/** Update count in the bar, zero width while the checkout is current. */
MouseArea {
    id: root

    property bool shown: DotsUpdates.hasUpdates || (DotsUpdates.opt("alwaysShow") ?? false)
    visible: shown
    implicitWidth: visible ? row.implicitWidth : 0
    implicitHeight: Appearance.sizes.barHeight
    hoverEnabled: true

    onClicked: {
        if (menu.active)
            menu.active = false;
        else
            menu.active = true;
    }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 2

        MaterialSymbol {
            fill: 0
            text: "system_update"
            iconSize: Appearance.font.pixelSize.larger
            color: DotsUpdates.hasUpdates ? Appearance.colors.colPrimary : Appearance.colors.colOnLayer1
        }

        StyledText {
            visible: DotsUpdates.hasUpdates
            text: `${DotsUpdates.behind}`
            font.pixelSize: Appearance.font.pixelSize.small
            color: DotsUpdates.hasUpdates ? Appearance.colors.colPrimary : Appearance.colors.colOnLayer1
        }
    }

    Loader {
        id: menu
        active: false

        sourceComponent: UpdatesPopup {
            anchor {
                window: root.QsWindow.window
                item: root
                gravity: Config.options.bar.vertical ? (Config.options.bar.bottom ? Edges.Left : Edges.Right) : (Config.options.bar.bottom ? Edges.Top : Edges.Bottom)
                edges: Config.options.bar.vertical ? (Config.options.bar.bottom ? Edges.Left : Edges.Right) : (Config.options.bar.bottom ? Edges.Top : Edges.Bottom)
            }
            onDismissed: menu.active = false
        }
    }
}
