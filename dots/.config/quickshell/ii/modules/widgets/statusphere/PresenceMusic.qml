pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.widgets
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.services
import QtQuick
import QtQuick.Layouts

/** One device's now playing: art, track, interpolated progress. */
Rectangle {
    id: root
    required property var device
    property var stackedDevice: null // Peeks out behind the art
    property int stackedCount: 0
    property bool compact: false // A photo already fills the card, so keep this to one thin line
    property bool _expanded: false // Tapped open out of the compact line

    onCompactChanged: if (!root.compact)
        root._expanded = false

    readonly property bool showingCompact: root.compact && !root._expanded

    radius: root.showingCompact ? 0 : Appearance.rounding.normal
    color: root.showingCompact ? "transparent" : Appearance.colors.colLayer2
    implicitHeight: content.implicitHeight + (root.showingCompact ? 0 : 24)

    Behavior on implicitHeight {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }

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

    MouseArea { // Tap the opened-up card to collapse it back to the compact line
        anchors.fill: content
        enabled: root.compact && !root.showingCompact
        cursorShape: Qt.PointingHandCursor
        onClicked: root._expanded = false
    }

    RowLayout {
        id: content
        anchors {
            left: parent.left
            right: parent.right
            verticalCenter: parent.verticalCenter
            margins: root.showingCompact ? 0 : 12
        }
        spacing: 16

        Item {
            visible: !root.showingCompact
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
                width: 46
                height: 46
                opacity: 0.7
            }

            PresenceArt {
                id: art
                source: root.device?.spotify_art_url ?? ""
                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                }
                width: 56
                height: 56
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

        Item { // Compact: title and a thin bar sharing one line, no art, no time
            Layout.fillWidth: true
            visible: root.showingCompact
            implicitHeight: compactLine.implicitHeight

            RowLayout {
                id: compactLine
                anchors.fill: parent
                spacing: 8

                StyledText {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    textFormat: Text.PlainText
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colSubtext
                    text: Statusphere.trackFor(root.device)
                }

                StyledProgressBar {
                    Layout.preferredWidth: 64
                    Layout.alignment: Qt.AlignVCenter
                    valueBarHeight: 3
                    wavy: root.device?.spotify_status === "playing"
                    highlightColor: Appearance.colors.colPrimary
                    trackColor: Appearance.colors.colSecondaryContainer
                    value: (root.length > 0) ? (root.interpolatedPosition / root.length) : 0
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root._expanded = true
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            visible: !root.showingCompact
            spacing: 6

            StyledText {
                Layout.fillWidth: true
                elide: Text.ElideRight
                textFormat: Text.PlainText
                font.pixelSize: Appearance.font.pixelSize.normal
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
}
