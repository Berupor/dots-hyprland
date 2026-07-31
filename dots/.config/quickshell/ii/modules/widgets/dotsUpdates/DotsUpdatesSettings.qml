import qs.modules.common
import qs.modules.common.widgets
import qs.modules.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

/** Where the dots checkout lives, plus what the last check made of it. */
ColumnLayout {
    id: page

    ContentSubsection {
        title: Translation.tr("Checkout")

        StyledText {
            Layout.fillWidth: true
            text: Translation.tr("The shell runs from a copy, so updates are read from the git checkout the config was installed from. Its current branch and the remote it tracks are used as they are.")
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Appearance.colors.colSubtext
            wrapMode: Text.WordWrap
        }

        MaterialTextArea {
            id: pathField
            Layout.fillWidth: true
            placeholderText: Translation.tr("Path to the dots repo")
            text: DotsUpdates.opt("repoPath") ?? ""
            wrapMode: TextEdit.Wrap
            onTextChanged: commitPath.restart()

            Timer {
                id: commitPath
                interval: 400 // Every keystroke would rewrite widgets.json
                onTriggered: DotsUpdates.setOpt("repoPath", pathField.text.trim())
            }
        }

        StyledText {
            Layout.fillWidth: true
            text: {
                switch (DotsUpdates.state) {
                case DotsUpdates.Status.Checking:
                    return Translation.tr("Checking…");
                case DotsUpdates.Status.NoRepo:
                    return Translation.tr("No git checkout there");
                case DotsUpdates.Status.NoUpstream:
                    return Translation.tr("Branch %1 tracks no remote").arg(DotsUpdates.branch);
                case DotsUpdates.Status.FetchFailed:
                    return Translation.tr("Could not reach the remote, checked %1").arg(DotsUpdates.sinceString(DotsUpdates.lastCheck));
                case DotsUpdates.Status.Behind:
                    return Translation.tr("%1 behind on %2, checked %3").arg(DotsUpdates.behind).arg(DotsUpdates.branch).arg(DotsUpdates.sinceString(DotsUpdates.lastCheck));
                case DotsUpdates.Status.UpToDate:
                    return Translation.tr("Up to date on %1, checked %2").arg(DotsUpdates.branch).arg(DotsUpdates.sinceString(DotsUpdates.lastCheck));
                }
                return Translation.tr("Not checked yet");
            }
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: (DotsUpdates.state === DotsUpdates.Status.NoRepo || DotsUpdates.state === DotsUpdates.Status.NoUpstream) ? Appearance.colors.colError : Appearance.colors.colSubtext
            wrapMode: Text.WordWrap
        }
    }

    ContentSubsection {
        title: Translation.tr("Notifications")

        StyledText {
            Layout.fillWidth: true
            text: Translation.tr("A notification carries an Update button. Skip drops that batch for good, ignoring it brings the same one back a day later. Off by default.")
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Appearance.colors.colSubtext
            wrapMode: Text.WordWrap
        }
    }
}
