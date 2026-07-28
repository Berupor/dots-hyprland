pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.services
import QtQuick
import QtQuick.Layouts

/** One device's now playing: art, track, interpolated progress. */
RowLayout {
    id: root
    required property var device
    property var stackedDevice: null // Peeks out behind the art
    property int stackedCount: 0

    readonly property real length: root.device?.spotify_length ?? 0
    readonly property real interpolatedPosition: root.device?.spotify_status ? root.projectedPosition(root._nowMs) : 0

    property real _nowMs: Date.now()

    Timer {
        interval: 250
        running: root.visible && root.device?.spotify_status === "playing"
        repeat: true
        onTriggered: root._nowMs = Date.now()
    }

    // Server positions are whole seconds and arrive a beat late, so run off our own clock and
    // only re-anchor on a seek, a track change or a play/pause - not on every sync.
    property real _anchorMs: Date.now()
    property real _anchorPos: 0
    property string _anchorStatus: ""
    property string _anchorTrack: ""

    function projectedPosition(nowMs: real): real {
        let pos = root._anchorPos;
        if (root._anchorStatus === "playing")
            pos += (nowMs - root._anchorMs) / 1000;
        if (root.length > 0)
            pos = Math.min(pos, root.length);
        return Math.max(0, pos);
    }

    onDeviceChanged: {
        const d = root.device;
        const rawPos = d?.spotify_position ?? 0;
        const status = d?.spotify_status ?? "";
        const track = d?.spotify_display ?? d?.spotify_track ?? "";
        if (status === root._anchorStatus && track === root._anchorTrack && Math.abs(rawPos - root.projectedPosition(Date.now())) <= 2)
            return;
        root._anchorMs = Date.now();
        root._nowMs = root._anchorMs;
        root._anchorPos = rawPos;
        root._anchorStatus = status;
        root._anchorTrack = track;
    }

    spacing: 8

    Item {
        Layout.alignment: Qt.AlignVCenter
        implicitWidth: art.width + (root.stackedCount > 0 ? 8 : 0)
        implicitHeight: art.height

        PresenceArt {
            visible: root.stackedCount > 0
            source: root.stackedDevice?.spotify_art_url ?? ""
            anchors {
                right: parent.right
                verticalCenter: parent.verticalCenter
            }
            width: 44
            height: 44
            opacity: 0.7
        }

        PresenceArt {
            id: art
            source: root.device?.spotify_art_url ?? ""
            anchors {
                left: parent.left
                verticalCenter: parent.verticalCenter
            }
            width: 52
            height: 52
        }

        MouseArea {
            id: artHover
            anchors.fill: art
            enabled: Statusphere.canSync(root.device)
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: Statusphere.syncSpotify(root.device)

            Rectangle {
                visible: artHover.containsMouse
                anchors.fill: parent
                radius: art.radius
                color: Appearance.colors.colScrim

                MaterialSymbol {
                    anchors.centerIn: parent
                    iconSize: Appearance.font.pixelSize.huge
                    color: "white"
                    text: "sync"
                }
            }

            StyledToolTip {
                extraVisibleCondition: false
                alternativeVisibleCondition: artHover.containsMouse
                text: Translation.tr("Play on your Spotify")
            }
        }

        Rectangle { // How many devices are playing, the stack alone reads as vague
            visible: root.stackedCount > 0
            anchors {
                horizontalCenter: art.right
                verticalCenter: art.bottom
            }
            implicitWidth: Math.max(18, countLabel.implicitWidth + 8)
            implicitHeight: 18
            radius: Appearance.rounding.full
            color: Appearance.colors.colSecondaryContainer
            border.width: 2
            border.color: Appearance.colors.colLayer2

            StyledText {
                id: countLabel
                anchors.centerIn: parent
                font.pixelSize: Appearance.font.pixelSize.smallest
                color: Appearance.colors.colOnSecondaryContainer
                text: root.stackedCount + 1
            }
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 4

        StyledText {
            Layout.fillWidth: true
            elide: Text.ElideRight
            textFormat: Text.PlainText
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Appearance.colors.colOnLayer2
            text: Statusphere.trackFor(root.device)
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            StyledProgressBar {
                Layout.fillWidth: true
                wavy: root.device?.spotify_status === "playing"
                highlightColor: Appearance.colors.colPrimary
                trackColor: Appearance.colors.colSecondaryContainer
                value: (root.length > 0) ? (root.interpolatedPosition / root.length) : 0
            }

            Row { // Digits in equal cells, else the bar resizes on every tick
                Layout.alignment: Qt.AlignVCenter

                TextMetrics {
                    id: digitCell
                    text: "0123456789" // Cell is the average digit, so spacing stays close to natural
                    font.family: Appearance.font.family.main
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.variableAxes: Appearance.font.variableAxes.main
                }

                Repeater {
                    model: `${StringUtils.friendlyTimeForSeconds(root.interpolatedPosition)} / ${StringUtils.friendlyTimeForSeconds(root.length)}`.split("")

                    delegate: StyledText {
                        required property string modelData
                        shouldUseNumberFont: false
                        width: /\d/.test(modelData) ? digitCell.width / 10 : implicitWidth
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colSubtext
                        text: modelData
                    }
                }
            }
        }
    }
}
