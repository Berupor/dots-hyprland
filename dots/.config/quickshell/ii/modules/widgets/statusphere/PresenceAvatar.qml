pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.widgets
import qs.modules.common.widgets
import qs.services
import QtQuick

/** The round face of a row. Holding your own opens the incognito picker. */
Item {
    id: root

    property var account: null
    property bool offline: true
    property bool hidden: false
    property bool interactive: false
    readonly property bool isServer: Statusphere.isServer(root.account)
    readonly property string health: Statusphere.healthFor(root.account)
    property real holdProgress: 0

    signal holdStarted
    signal holdMoved(real x, real y)
    signal holdEnded
    signal tapped

    readonly property int holdDuration: 420

    implicitWidth: 40
    implicitHeight: 40

    onHiddenChanged: pop.restart()

    SequentialAnimation {
        id: pop
        NumberAnimation {
            target: face
            property: "scale"
            to: 0.82
            duration: 90
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: face
            property: "scale"
            to: 1
            duration: 400
            easing.type: Easing.OutBack
            easing.overshoot: 3.2
        }
    }

    CircularProgress { // Fills while you hold, then hands over to the picker
        anchors.centerIn: parent
        implicitSize: root.width + 10
        lineWidth: 3
        enableAnimation: false
        value: root.holdProgress
        opacity: root.holdProgress > 0 ? 1 : 0
        colPrimary: Appearance.colors.colPrimary
        colSecondary: "transparent"

        Behavior on opacity {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }
    }

    Item {
        id: face
        anchors.fill: parent

        MaterialShape {
            anchors.fill: parent
            shape: MaterialShape.Shape.Circle
            color: root.offline ? Appearance.colors.colLayer2 : Appearance.colors.colSecondaryContainer
        }

        StyledText {
            anchors.centerIn: parent
            opacity: (root.hidden || root.isServer) ? 0 : 1
            font.pixelSize: Appearance.font.pixelSize.large
            color: root.offline ? Appearance.colors.colSubtext : Appearance.colors.colOnSecondaryContainer
            text: Statusphere.initialFor(root.account)

            Behavior on opacity {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }
        }

        MaterialSymbol { // A machine has no initial worth showing
            anchors.centerIn: parent
            opacity: (root.isServer && !root.hidden) ? 1 : 0
            fill: 0
            text: "dns"
            iconSize: Appearance.font.pixelSize.larger
            color: root.offline ? Appearance.colors.colSubtext : Appearance.colors.colOnSecondaryContainer

            Behavior on opacity {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }
        }

        MaterialSymbol {
            anchors.centerIn: parent
            opacity: root.hidden ? 1 : 0
            fill: 0
            text: "visibility_off"
            iconSize: Appearance.font.pixelSize.larger
            color: Appearance.colors.colOnSecondaryContainer

            Behavior on opacity {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }
        }
    }

    Rectangle {
        width: 12
        height: 12
        radius: 6
        anchors {
            right: parent.right
            bottom: parent.bottom
        }
        color: {
            if (root.offline)
                return Appearance.colors.colLayer2;
            if (root.hidden)
                return Appearance.colors.colSecondary;
            if (root.health === "crit")
                return Appearance.colors.colError;
            if (root.health === "warn")
                return Appearance.colors.colTertiary;
            return Appearance.colors.colPrimary;
        }
        border.width: 2
        border.color: Appearance.colors.colLayer2

        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }
    }

    MouseArea {
        id: gesture
        anchors.fill: parent
        enabled: root.interactive
        preventStealing: true // The row scrolls under it, and a slid finger belongs to the picker

        property bool picking: false

        onPressed: {
            gesture.picking = false;
            hold.restart();
        }
        onPositionChanged: mouse => {
            if (gesture.picking)
                root.holdMoved(mouse.x, mouse.y);
        }
        onReleased: gesture.finish()
        onCanceled: gesture.finish()

        function finish(): void {
            hold.stop();
            root.holdProgress = 0;
            if (!gesture.picking) {
                root.tapped();
                return;
            }
            gesture.picking = false;
            root.holdEnded();
        }

        NumberAnimation {
            id: hold
            target: root
            property: "holdProgress"
            from: 0
            to: 1
            duration: root.holdDuration
            onFinished: {
                gesture.picking = true;
                root.holdProgress = 0;
                root.holdStarted();
            }
        }
    }
}
