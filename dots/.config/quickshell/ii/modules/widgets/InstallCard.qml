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
CatalogCard {
    id: root
    readonly property string templateUrl: "https://github.com/Berupor/ii-widget-hello"
    readonly property bool installing: WidgetInstaller.busy && WidgetInstaller.job === ""
    readonly property bool failed: WidgetInstaller.job === "" && WidgetInstaller.state === WidgetInstaller.State.Failed

    icon: "download"
    title: Translation.tr("Install a widget")
    // The installer talks here, so the header stays the only status line
    subtitle: WidgetInstaller.job === "" && WidgetInstaller.message !== "" ? WidgetInstaller.message : Translation.tr("From a git repository")
    subtitleColor: root.failed ? Appearance.colors.colError : Appearance.colors.colSubtext
    iconColor: Appearance.colors.colSecondaryContainer
    iconSymbolColor: Appearance.colors.colOnSecondaryContainer

    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        MaterialTextArea {
            id: urlField
            Layout.fillWidth: true
            placeholderText: Translation.tr("Repository url")
            wrapMode: TextEdit.WrapAnywhere // A url has nowhere to break by words
            onTextChanged: if (WidgetInstaller.job === "")
                WidgetInstaller.state = WidgetInstaller.State.Idle
        }

        RippleButtonWithIcon {
            Layout.alignment: Qt.AlignVCenter
            buttonRadius: Appearance.rounding.small
            enabled: urlField.text.trim() !== "" && !WidgetInstaller.busy
            materialIcon: root.installing ? "hourglass_top" : "download"
            mainText: root.installing ? Translation.tr("Installing...") : Translation.tr("Install")
            onClicked: WidgetInstaller.install(urlField.text)

            StyledToolTip {
                text: Translation.tr("Clones into %1").arg(WidgetCatalog.externalDir)
            }
        }
    }

    StyledText {
        Layout.fillWidth: true
        Layout.topMargin: 2
        // The link fills the field above rather than opening a page: nothing else to do with it here
        text: Translation.tr("A widget is part of the shell once installed and runs with it. Install what you would run yourself, or start with %1.").arg(`[hello](${root.templateUrl})`)
        font.pixelSize: Appearance.font.pixelSize.smaller
        color: Appearance.colors.colSubtext
        textFormat: Text.MarkdownText
        wrapMode: Text.WordWrap
        onLinkActivated: link => urlField.text = link

        PointingHandLinkHover {}
    }
}
