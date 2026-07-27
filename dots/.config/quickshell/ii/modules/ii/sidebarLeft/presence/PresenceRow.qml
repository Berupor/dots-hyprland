pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.services
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

Rectangle {
    id: root
    required property string modelData

    readonly property var account: Statusphere.accountsById[root.modelData] ?? null
    readonly property bool offline: root.account?.offline ?? true
    readonly property var primary: root.account?.primary ?? null
    readonly property bool nowPlaying: !root.offline && !!root.primary?.spotify_status
    readonly property bool activelyPlaying: root.nowPlaying && root.primary?.spotify_status === "playing"

    property real _nowMs: Date.now()

    Timer {
        interval: 250
        running: root.activelyPlaying
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
        const length = root.primary?.spotify_length ?? 0;
        if (length > 0)
            pos = Math.min(pos, length);
        return Math.max(0, pos);
    }

    onPrimaryChanged: {
        const p = root.primary;
        const rawPos = p?.spotify_position ?? 0;
        const status = p?.spotify_status ?? "";
        const track = p?.spotify_display ?? p?.spotify_track ?? "";
        if (status === root._anchorStatus && track === root._anchorTrack && Math.abs(rawPos - root.projectedPosition(Date.now())) <= 2)
            return;
        root._anchorMs = Date.now();
        root._nowMs = root._anchorMs;
        root._anchorPos = rawPos;
        root._anchorStatus = status;
        root._anchorTrack = track;
    }

    readonly property real interpolatedPosition: root.primary?.spotify_status ? root.projectedPosition(root._nowMs) : 0

    Layout.fillWidth: true
    implicitHeight: content.implicitHeight + 24
    radius: Appearance.rounding.normal
    color: Appearance.colors.colLayer2
    opacity: root.offline ? 0.6 : 1

    ColumnLayout {
        id: content
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 12
        }
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Item {
                id: avatar
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: 40
                implicitHeight: 40

                MaterialShape {
                    anchors.fill: parent
                    shape: MaterialShape.Shape.Circle
                    color: root.offline ? Appearance.colors.colLayer1 : Appearance.colors.colSecondaryContainer
                }

                StyledText {
                    anchors.centerIn: parent
                    font.pixelSize: Appearance.font.pixelSize.large
                    color: root.offline ? Appearance.colors.colSubtext : Appearance.colors.colOnSecondaryContainer
                    text: Statusphere.initialFor(root.account)
                }

                Rectangle {
                    width: 12
                    height: 12
                    radius: 6
                    anchors {
                        right: parent.right
                        bottom: parent.bottom
                    }
                    color: root.offline ? Appearance.colors.colLayer2 : Appearance.colors.colPrimary
                    border.width: 2
                    border.color: Appearance.colors.colLayer2
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                StyledText {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    textFormat: Text.PlainText
                    color: Appearance.colors.colOnLayer2
                    text: Statusphere.nameFor(root.account)
                }

                StyledText {
                    Layout.fillWidth: true
                    visible: text.length > 0
                    elide: Text.ElideRight
                    textFormat: Text.PlainText
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colSubtext
                    text: root.offline ? Translation.tr("Offline") : Statusphere.statusFor(root.account)
                }
            }

            Rectangle {
                id: weatherChip
                readonly property string weatherText: Statusphere.weatherFor(root.account)
                visible: !root.offline && weatherText !== ""
                Layout.alignment: Qt.AlignVCenter
                radius: Appearance.rounding.full
                color: Appearance.colors.colLayer1
                implicitWidth: weatherLabel.implicitWidth + 16
                implicitHeight: weatherLabel.implicitHeight + 6

                StyledText {
                    id: weatherLabel
                    anchors.centerIn: parent
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colSubtext
                    text: weatherChip.weatherText
                }
            }

            MaterialSymbol {
                Layout.alignment: Qt.AlignVCenter
                visible: !root.offline && !root.nowPlaying
                iconSize: Appearance.font.pixelSize.larger
                color: Appearance.colors.colOnLayer2
                text: Statusphere.iconFor(root.account)
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 52 // Lines up with the name above, past the avatar
            visible: root.nowPlaying
            spacing: 8

            Rectangle {
                id: artThumb
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: 52
                implicitHeight: 52
                radius: Appearance.rounding.small
                color: Appearance.colors.colLayer1

                StyledImage {
                    id: artImage
                    anchors.fill: parent
                    source: root.primary?.spotify_art_url ?? ""
                    fillMode: Image.PreserveAspectCrop
                    cache: true

                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: Rectangle {
                            width: artImage.width
                            height: artImage.height
                            radius: artThumb.radius
                        }
                    }
                }

                MaterialSymbol {
                    visible: artImage.status !== Image.Ready
                    anchors.centerIn: parent
                    iconSize: Appearance.font.pixelSize.huge
                    color: Appearance.colors.colSubtext
                    text: "music_note"
                }

                MouseArea {
                    id: artHover
                    anchors.fill: parent
                    hoverEnabled: Statusphere.canSync(root.account)
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Statusphere.syncSpotify(root.account)

                    Rectangle {
                        visible: artHover.containsMouse
                        anchors.fill: parent
                        radius: artThumb.radius
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
                    text: Statusphere.nowPlayingFor(root.account)
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    StyledProgressBar {
                        Layout.fillWidth: true
                        wavy: root.primary?.spotify_status === "playing"
                        highlightColor: Appearance.colors.colPrimary
                        trackColor: Appearance.colors.colSecondaryContainer
                        value: (root.primary?.spotify_length > 0) ? (root.interpolatedPosition / root.primary.spotify_length) : 0
                    }

                    StyledText {
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colSubtext
                        text: `${StringUtils.friendlyTimeForSeconds(root.interpolatedPosition)} / ${StringUtils.friendlyTimeForSeconds(root.primary?.spotify_length)}`
                    }
                }
            }
        }
    }

    property bool showDetails: false

    MouseArea { // Hold right click for the noisy stuff (cpu/mem/disk, workspace, last seen)
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        onPressed: root.showDetails = true
        onReleased: root.showDetails = false
        onCanceled: root.showDetails = false

        StyledToolTip {
            extraVisibleCondition: false
            alternativeVisibleCondition: root.showDetails
            text: Statusphere.detailFor(root.account)
        }
    }
}
