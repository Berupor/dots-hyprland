pragma ComponentBehavior: Bound

// Vpn menu body: status strip, tunnel facts as chips, profile list, entry to the tui.
// Split from VpnPopup's window frame so widget-probe can render it.

import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.widgets
import qs.services
import QtQuick
import QtQuick.Layouts
import Quickshell

Item {
    id: root

    signal requestClose

    readonly property real padding: 8
    // Profile names are short ("work", "home"), a floor keeps the strip and the chips
    // from collapsing
    readonly property real minContentWidth: 230

    implicitWidth: Math.max(root.minContentWidth, column.implicitWidth + root.padding * 2)
    implicitHeight: column.implicitHeight + root.padding * 2

    // One fact about the live tunnel
    component DetailChip: Pill {
        id: chip
        property string icon
        property string label
        implicitWidth: chipRow.implicitWidth + 20
        implicitHeight: 26
        color: Appearance.colors.colLayer3

        RowLayout {
            id: chipRow
            anchors.centerIn: parent
            spacing: 4

            MaterialSymbol {
                text: chip.icon
                iconSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colOnSurfaceVariant
            }
            StyledText {
                text: chip.label
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colOnSurfaceVariant
                textFormat: Text.PlainText
            }
        }
    }

    ColumnLayout {
        id: column
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: root.padding
        }
        spacing: 4

        Rectangle { // Status strip
            Layout.fillWidth: true
            implicitHeight: statusRow.implicitHeight + 8 * 2
            radius: Appearance.rounding.small
            color: VpnStatus.connected ? Appearance.colors.colSecondaryContainer : Appearance.colors.colLayer3

            Behavior on color {
                animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
            }

            RowLayout {
                id: statusRow
                anchors {
                    left: parent.left
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                    leftMargin: 8
                    rightMargin: 12
                }
                spacing: 10

                // ShapeCanvas morphs between the two shapes, so connecting is animated
                MaterialShapeWrappedMaterialSymbol {
                    Layout.alignment: Qt.AlignVCenter
                    shape: VpnStatus.connected ? MaterialShape.Shape.Clover4Leaf : MaterialShape.Shape.Circle
                    text: VpnStatus.icon
                    iconSize: Appearance.font.pixelSize.large
                    padding: 7
                    color: VpnStatus.connected ? Appearance.colors.colPrimary : Appearance.colors.colSurfaceContainerHighest
                    colSymbol: VpnStatus.connected ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSurfaceVariant

                    Behavior on color {
                        animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    text: (VpnStatus.connected && VpnStatus.vpnName !== "") ? VpnStatus.vpnName : Translation.tr("VPN")
                    font.pixelSize: Appearance.font.pixelSize.normal
                    font.weight: Font.Medium
                    color: VpnStatus.connected ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer3
                    elide: Text.ElideRight
                    textFormat: Text.PlainText
                }

                // Connected needs no word: the strip is filled and the chips below say more
                StyledText {
                    visible: !VpnStatus.connected
                    text: Translation.tr("Off")
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colSubtext
                }
            }
        }

        Flow { // Tunnel facts, wraps when the addresses are long
            Layout.fillWidth: true
            visible: VpnStatus.connected
            spacing: 4

            DetailChip {
                visible: VpnStatus.vpnIp !== ""
                icon: "lan"
                label: VpnStatus.vpnIp
            }
            DetailChip {
                visible: VpnStatus.mode !== ""
                icon: "alt_route"
                label: VpnStatus.mode === "split" ? Translation.tr("Split, %1 routes").arg(VpnStatus.routes) : VpnStatus.mode === "full" ? Translation.tr("Full tunnel") : VpnStatus.mode
            }
        }

        StyledText {
            Layout.leftMargin: 8
            Layout.topMargin: 2
            text: VpnStatus.profiles.length > 0 ? Translation.tr("Profiles") : Translation.tr("No profiles")
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Appearance.colors.colSubtext
        }

        ColumnLayout { // Rows flush, they group by hover shape rather than by gaps
            Layout.fillWidth: true
            spacing: 0

            Repeater {
                model: VpnStatus.profiles
                delegate: RippleButton {
                    id: profileRow
                    required property var modelData
                    readonly property bool isActive: modelData.active === true
                    readonly property color colText: profileRow.isActive ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnSurfaceVariant

                    Layout.fillWidth: true
                    implicitHeight: 36
                    horizontalPadding: 10
                    buttonRadius: Appearance.rounding.verysmall
                    toggled: profileRow.isActive

                    colBackground: ColorUtils.transparentize(Appearance.colors.colLayer3)
                    colBackgroundHover: Appearance.colors.colLayer3Hover
                    colRipple: Appearance.colors.colLayer3Active
                    colBackgroundToggled: Appearance.colors.colSecondaryContainer
                    colBackgroundToggledHover: Appearance.colors.colSecondaryContainerHover
                    colRippleToggled: Appearance.colors.colSecondaryContainerActive

                    releaseAction: () => {
                        if (profileRow.isActive)
                            VpnStatus.disconnect(profileRow.modelData.name);
                        else
                            VpnStatus.connect(profileRow.modelData.name);
                        root.requestClose();
                    }

                    contentItem: RowLayout {
                        anchors {
                            verticalCenter: parent.verticalCenter
                            left: parent.left
                            right: parent.right
                            leftMargin: profileRow.horizontalPadding
                            rightMargin: profileRow.horizontalPadding
                        }
                        spacing: 10

                        MaterialSymbol {
                            text: profileRow.isActive ? "vpn_lock" : "vpn_key"
                            fill: profileRow.isActive ? 1 : 0
                            iconSize: Appearance.font.pixelSize.large
                            color: profileRow.colText
                        }
                        StyledText {
                            Layout.fillWidth: true
                            text: profileRow.modelData.name
                            elide: Text.ElideRight
                            textFormat: Text.PlainText
                            color: profileRow.colText
                        }
                        // Turns into disconnect on hover, clicking the active profile drops the tunnel
                        MaterialSymbol {
                            visible: profileRow.isActive
                            text: profileRow.hovered ? "link_off" : "check"
                            iconSize: Appearance.font.pixelSize.large
                            color: profileRow.colText
                        }
                    }
                }
            }
        }

        RippleButtonWithIcon { // Open the full tui manager
            Layout.fillWidth: true
            Layout.topMargin: 4
            implicitHeight: 34
            buttonRadius: Appearance.rounding.full
            colBackground: Appearance.colors.colLayer3
            colBackgroundHover: Appearance.colors.colLayer3Hover
            colRipple: Appearance.colors.colLayer3Active
            materialIcon: "tune"
            materialIconFill: false
            mainText: Translation.tr("Open manager…")
            onClicked: {
                Quickshell.execDetached(["bash", "-c", `${Config.options.apps.terminal} -e $HOME/.local/bin/vpn`]);
                root.requestClose();
            }
        }
    }
}
