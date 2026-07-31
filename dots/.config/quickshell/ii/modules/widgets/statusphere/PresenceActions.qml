pragma ComponentBehavior: Bound

import qs
import qs.modules.common
import qs.modules.widgets
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts
import Quickshell

/** Middle-click-expanded actions on your own card. Sharing replaces your previous photo. */
ColumnLayout {
    id: root
    property var photo: null // Your own live share, if any

    readonly property string shareStatus: {
        if (Statusphere.lastPostError)
            return Statusphere.lastPostError;
        if (Statusphere.posting)
            return Translation.tr("Sharing…");
        if (root.photo)
            return Translation.tr("Shared until %1").arg(Qt.formatTime(new Date(Date.parse(root.photo.expires_at)), "HH:mm"));
        return Translation.tr("Middle-drag a region to share it right away");
    }

    spacing: 6

    // Same anatomy as the android quick toggles: icon chip, name, status under it
    component ActionPill: RippleButton {
        id: pill
        property string buttonIcon
        property string title
        property string status
        property bool active: false
        property bool failed: false

        Layout.fillWidth: true
        implicitHeight: 52
        padding: 6
        horizontalPadding: padding
        verticalPadding: padding
        buttonRadius: height / 2
        buttonRadiusPressed: Appearance.rounding.normal
        colBackground: Appearance.colors.colLayer2
        colBackgroundHover: Appearance.colors.colLayer2Hover
        colRipple: Appearance.colors.colLayer2Active

        contentItem: RowLayout {
            spacing: 10

            Rectangle {
                Layout.fillHeight: true
                implicitWidth: height
                radius: Appearance.rounding.full
                color: pill.active ? Appearance.colors.colPrimary : Appearance.colors.colLayer3

                Behavior on color {
                    animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                }

                MaterialSymbol {
                    anchors.centerIn: parent
                    iconSize: 22
                    fill: pill.active ? 1 : 0
                    color: pill.active ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer3
                    text: pill.buttonIcon
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.rightMargin: 8
                spacing: -2

                StyledText {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    font.pixelSize: Appearance.font.pixelSize.smallie
                    font.weight: 600
                    color: Appearance.colors.colOnLayer2
                    text: pill.title
                }

                StyledText {
                    Layout.fillWidth: true
                    visible: text.length > 0
                    elide: Text.ElideRight
                    font {
                        pixelSize: Appearance.font.pixelSize.smaller
                        weight: 100
                    }
                    color: pill.failed ? Appearance.colors.colError : Appearance.colors.colSubtext
                    text: pill.status
                }
            }
        }
    }

    ActionPill {
        buttonIcon: Statusphere.lastPostError ? "error" : "screenshot_region"
        title: Translation.tr("Share a screen region")
        status: root.shareStatus
        active: Statusphere.posting
        failed: Statusphere.lastPostError.length > 0
        onClicked: {
            GlobalStates.sidebarLeftOpen = false;
            Quickshell.execDetached(["qs", "-p", Quickshell.shellPath(""), "ipc", "call", "region", "widget", "share"]);
        }
    }
}
