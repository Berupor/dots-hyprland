import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.widgets

/**
 * Installing a widget from a git url. It lands in the user widget dir and shows
 * up in the list above, where it can be updated or removed again.
 */
ContentSection {
    id: section
    readonly property bool installing: WidgetInstaller.busy && WidgetInstaller.job === ""

    icon: "download"
    title: Translation.tr("Install a widget")

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 4

        MaterialTextArea {
            id: urlField
            Layout.fillWidth: true
            placeholderText: Translation.tr("Repository url")
            wrapMode: TextEdit.WrapAnywhere // A url has nowhere to break by words
            onTextChanged: if (WidgetInstaller.job === "")
                WidgetInstaller.state = WidgetInstaller.State.Idle
        }

        StyledText {
            Layout.fillWidth: true
            Layout.leftMargin: 2
            text: Translation.tr("A widget is part of the shell once installed and runs with it. Install what you would run yourself.")
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Appearance.colors.colSubtext
            wrapMode: Text.WordWrap
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 4
            spacing: 8

            StyledText { // Fills even while empty, so the button stays right
                Layout.fillWidth: true
                Layout.leftMargin: 2
                text: WidgetInstaller.job === "" ? WidgetInstaller.message : ""
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: WidgetInstaller.state === WidgetInstaller.State.Failed ? Appearance.colors.colError : Appearance.colors.colSubtext
                wrapMode: Text.WordWrap
            }

            RippleButtonWithIcon {
                Layout.alignment: Qt.AlignRight
                buttonRadius: Appearance.rounding.small
                enabled: urlField.text.trim() !== "" && !WidgetInstaller.busy
                materialIcon: section.installing ? "hourglass_top" : "download"
                mainText: section.installing ? Translation.tr("Installing...") : Translation.tr("Install")
                onClicked: WidgetInstaller.install(urlField.text)

                StyledToolTip {
                    text: Translation.tr("Clones into %1").arg(WidgetCatalog.externalDir)
                }
            }
        }
    }
}
