pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    required property string modelData

    readonly property var account: Statusphere.accountsById[root.modelData] ?? null
    readonly property bool offline: root.account?.offline ?? true
    readonly property var devices: root.account?.devices ?? []
    readonly property var playing: Statusphere.musicDevices(root.account)
    readonly property var currentPhoto: Statusphere.currentPhotoFor(root.account)
    readonly property bool hasPhoto: Config.options.sidebar.statusphere.photo.enable && root.currentPhoto !== null
    readonly property bool expandable: root.devices.length > 1
    property bool expanded: false

    onExpandableChanged: if (!root.expandable)
        root.expanded = false

    Layout.fillWidth: true
    implicitHeight: content.implicitHeight + 24
    radius: Appearance.rounding.normal
    color: Appearance.colors.colLayer1
    opacity: root.offline ? 0.6 : 1

    Behavior on implicitHeight {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }

    MouseArea { // Under everything, so art sync and the details tooltip get their clicks first
        anchors.fill: parent
        enabled: root.expandable
        onClicked: root.expanded = !root.expanded
    }

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
                    color: root.offline ? Appearance.colors.colLayer2 : Appearance.colors.colSecondaryContainer
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

            Rectangle { // The status line only ever speaks for one device, so count them here
                visible: !root.offline && root.expandable
                Layout.alignment: Qt.AlignVCenter
                radius: Appearance.rounding.full
                color: Appearance.colors.colLayer1
                implicitWidth: deviceChip.implicitWidth + 14
                implicitHeight: deviceChip.implicitHeight + 6

                RowLayout {
                    id: deviceChip
                    anchors.centerIn: parent
                    spacing: 2

                    MaterialSymbol {
                        text: root.expanded ? "expand_less" : "devices"
                        iconSize: Appearance.font.pixelSize.normal
                        color: Appearance.colors.colSubtext
                    }

                    StyledText {
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colSubtext
                        text: root.devices.length
                    }
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
        }

        PresencePhoto {
            Layout.fillWidth: true
            Layout.topMargin: 8
            visible: root.hasPhoto && !root.expanded
            photo: root.currentPhoto
        }

        Rectangle { // Only needed between the photo and the compact music line below it
            visible: root.hasPhoto && music.visible && music.showingCompact
            Layout.fillWidth: true
            implicitHeight: 1
            color: Appearance.colors.colOutlineVariant
        }

        PresenceMusic { // One art with the rest of the stack peeking out behind it, unless a photo already fills the space
            id: music
            Layout.fillWidth: true
            visible: root.playing.length > 0 && !root.expanded
            compact: root.hasPhoto
            device: root.playing[0] ?? null
            stackedDevice: root.playing[1] ?? null
            stackedCount: root.playing.length - 1
        }

        ColumnLayout { // Expanded: the music once per track, then what each device is up to
            Layout.fillWidth: true
            Layout.leftMargin: 52
            visible: root.expanded
            spacing: 8

            Repeater {
                model: root.expanded ? root.playing : []

                delegate: ColumnLayout {
                    id: trackEntry
                    required property var modelData
                    required property int index

                    Layout.fillWidth: true
                    spacing: 8

                    Rectangle {
                        visible: trackEntry.index > 0
                        Layout.fillWidth: true
                        implicitHeight: 1
                        color: Appearance.colors.colOutlineVariant
                    }

                    PresenceMusic {
                        Layout.fillWidth: true
                        device: trackEntry.modelData
                    }
                }
            }

            Rectangle {
                visible: root.playing.length > 0
                Layout.fillWidth: true
                implicitHeight: 1
                color: Appearance.colors.colOutlineVariant
            }

            Repeater {
                model: root.expanded ? root.devices : []

                delegate: StyledText {
                    required property var modelData
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    textFormat: Text.PlainText
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colSubtext
                    text: Statusphere.deviceStatusFor(modelData)
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
