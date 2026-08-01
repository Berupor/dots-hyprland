import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.widgets

/**
 * Where widget failure reports go. Keys are documented in ErrorReporter.
 */
CatalogCard {
    id: root
    readonly property bool sending: ErrorReporter.sending

    /// Host, so a long url does not push the header around
    readonly property string host: ErrorReporter.target.replace(/^\w+:\/\//, "").split("/")[0]

    icon: "bug_report"
    title: Translation.tr("Error reports")
    subtitle: root.sending ? Translation.tr("Sent to %1").arg(root.host) : Translation.tr("Nothing leaves this machine")
    iconColor: Appearance.colors.colSecondaryContainer
    iconSymbolColor: Appearance.colors.colOnSecondaryContainer

    ContentSubsectionLabel {
        text: Translation.tr("When a widget fails")
    }

    ConfigSwitch {
        buttonIcon: "send"
        text: Translation.tr("Send the failure to the widget author")
        checked: root.sending
        onCheckedChanged: WidgetsStore.setKey("errorReports", checked ? "always" : "never")
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: 4
        spacing: 8

        StyledText {
            Layout.fillWidth: true
            text: Translation.tr("The error goes out with the last 100 log lines, window titles and paths included. Same widget and message goes out once per session.")
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Appearance.colors.colSubtext
            wrapMode: Text.WordWrap
        }

        RippleButtonWithIcon {
            Layout.alignment: Qt.AlignVCenter
            buttonRadius: Appearance.rounding.small
            enabled: ErrorReporter.testState !== ErrorReporter.TestState.Sending
            materialIcon: {
                switch (ErrorReporter.testState) {
                case ErrorReporter.TestState.Sent:
                    return "check";
                case ErrorReporter.TestState.Failed:
                    return "error";
                }
                return "outgoing_mail";
            }
            mainText: {
                switch (ErrorReporter.testState) {
                case ErrorReporter.TestState.Sending:
                    return Translation.tr("Sending...");
                case ErrorReporter.TestState.Sent:
                    return Translation.tr("Sent");
                case ErrorReporter.TestState.Failed:
                    return Translation.tr("Failed");
                }
                return Translation.tr("Send test");
            }
            onClicked: ErrorReporter.test()

            StyledToolTip {
                text: Translation.tr("Sends one report as a broken widget would, whatever the switch says")
            }
        }
    }
}
