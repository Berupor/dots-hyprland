pragma ComponentBehavior: Bound

// Updates menu body: what's waiting, the first few subjects, pull and check.
// Split from UpdatesPopup's window frame so widget-probe can render it.

import qs.modules.common
import qs.modules.common.widgets
import qs.modules.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    signal requestClose

    readonly property real padding: 8
    readonly property real minContentWidth: 260
    readonly property real maxSubjectWidth: 320
    readonly property int shownCommits: 5
    readonly property var subjects: DotsUpdates.commits.slice(0, root.shownCommits)

    readonly property string stateText: {
        switch (DotsUpdates.state) {
        case DotsUpdates.Status.NoRepo:
            return Translation.tr("No git checkout at %1").arg(DotsUpdates.opt("repoPath") ?? "");
        case DotsUpdates.Status.NoUpstream:
            return Translation.tr("The checked out branch tracks no remote");
        case DotsUpdates.Status.FetchFailed:
            return Translation.tr("Could not reach the remote");
        }
        return Translation.tr("Checked %1").arg(DotsUpdates.sinceString(DotsUpdates.lastCheck));
    }

    implicitWidth: Math.max(root.minContentWidth, column.implicitWidth + root.padding * 2)
    implicitHeight: column.implicitHeight + root.padding * 2

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
            color: DotsUpdates.hasUpdates ? Appearance.colors.colSecondaryContainer : Appearance.colors.colLayer3

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

                MaterialShapeWrappedMaterialSymbol {
                    Layout.alignment: Qt.AlignVCenter
                    shape: DotsUpdates.hasUpdates ? MaterialShape.Shape.Clover4Leaf : MaterialShape.Shape.Circle
                    text: "system_update"
                    iconSize: Appearance.font.pixelSize.large
                    padding: 7
                    color: DotsUpdates.hasUpdates ? Appearance.colors.colPrimary : Appearance.colors.colSurfaceContainerHighest
                    colSymbol: DotsUpdates.hasUpdates ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSurfaceVariant

                    Behavior on color {
                        animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    StyledText {
                        Layout.fillWidth: true
                        text: DotsUpdates.hasUpdates ? (DotsUpdates.behind === 1 ? Translation.tr("1 new commit") : Translation.tr("%1 new commits").arg(DotsUpdates.behind)) : Translation.tr("Up to date")
                        font.pixelSize: Appearance.font.pixelSize.normal
                        font.weight: Font.Medium
                        color: DotsUpdates.hasUpdates ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer3
                        elide: Text.ElideRight
                        textFormat: Text.PlainText
                    }

                    StyledText {
                        Layout.fillWidth: true
                        visible: DotsUpdates.branch !== ""
                        text: DotsUpdates.branch
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: DotsUpdates.hasUpdates ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colSubtext
                        elide: Text.ElideRight
                        textFormat: Text.PlainText
                    }
                }
            }
        }

        ColumnLayout { // Subjects, newest first
            Layout.fillWidth: true
            Layout.topMargin: 2
            Layout.leftMargin: 8
            visible: root.subjects.length > 0
            spacing: 2

            Repeater {
                model: root.subjects

                delegate: StyledText {
                    required property string modelData
                    Layout.fillWidth: true
                    Layout.maximumWidth: root.maxSubjectWidth
                    text: modelData
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colOnSurfaceVariant
                    elide: Text.ElideRight
                    textFormat: Text.PlainText
                }
            }

            StyledText {
                visible: DotsUpdates.behind > root.subjects.length
                text: Translation.tr("and %1 more").arg(DotsUpdates.behind - root.subjects.length)
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colSubtext
            }
        }

        StyledText {
            Layout.fillWidth: true
            Layout.maximumWidth: root.maxSubjectWidth
            Layout.leftMargin: 8
            Layout.topMargin: 2
            text: root.stateText
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: DotsUpdates.state === DotsUpdates.Status.NoRepo || DotsUpdates.state === DotsUpdates.Status.NoUpstream ? Appearance.colors.colError : Appearance.colors.colSubtext
            wrapMode: Text.WordWrap
        }

        RippleButtonWithIcon { // Pull and reinstall the files
            Layout.fillWidth: true
            Layout.topMargin: 4
            implicitHeight: 34
            visible: DotsUpdates.hasUpdates
            buttonRadius: Appearance.rounding.full
            colBackground: Appearance.colors.colSecondaryContainer
            colBackgroundHover: Appearance.colors.colSecondaryContainerHover
            colRipple: Appearance.colors.colSecondaryContainerActive
            materialIcon: "download"
            materialIconFill: false
            mainText: Translation.tr("Update and reload")
            onClicked: {
                DotsUpdates.update();
                root.requestClose();
            }

            StyledToolTip {
                text: Translation.tr("Runs git pull and the installer in a terminal.\nLocal edits in ~/.config/quickshell are replaced")
            }
        }

        RippleButtonWithIcon {
            Layout.fillWidth: true
            Layout.topMargin: 2
            implicitHeight: 34
            enabled: !DotsUpdates.checking
            buttonRadius: Appearance.rounding.full
            colBackground: Appearance.colors.colLayer3
            colBackgroundHover: Appearance.colors.colLayer3Hover
            colRipple: Appearance.colors.colLayer3Active
            materialIcon: "refresh"
            materialIconFill: false
            mainText: DotsUpdates.checking ? Translation.tr("Checking…") : Translation.tr("Check for updates")
            onClicked: DotsUpdates.check()
        }
    }
}
