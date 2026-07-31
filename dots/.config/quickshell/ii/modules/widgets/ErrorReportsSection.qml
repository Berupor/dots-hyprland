import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.widgets

/**
 * Where widget failure reports go. Keys are documented in ErrorReporter.
 */
ContentSection {
    id: section
    readonly property string mode: WidgetsStore.data.errorReports ?? "ask"
    readonly property string channel: WidgetsStore.data.errorReportsChannel ?? "ntfy"
    readonly property string target: WidgetsStore.data.errorReportsTarget ?? ""

    icon: "bug_report"
    title: Translation.tr("Error reports")

    onChannelChanged: ErrorReporter.testState = ErrorReporter.TestState.Idle

    StyledText {
        Layout.fillWidth: true
        text: Translation.tr("A failing widget can send its error along with the last 100 log lines. Logs carry window titles and paths, so nothing is sent until a target is set here.")
        font.pixelSize: Appearance.font.pixelSize.smaller
        color: Appearance.colors.colSubtext
        wrapMode: Text.WordWrap
    }

    ConfigRow {
        ColumnLayout {
            ContentSubsectionLabel {
                text: Translation.tr("When a widget fails")
            }

            ConfigSelectionArray {
                currentValue: section.mode
                onSelected: newValue => WidgetsStore.setKey("errorReports", newValue)
                options: [
                    {
                        displayName: Translation.tr("Ask"),
                        icon: "contact_support",
                        value: "ask"
                    },
                    {
                        displayName: Translation.tr("Send"),
                        icon: "send",
                        value: "always"
                    },
                    {
                        displayName: Translation.tr("Never"),
                        icon: "block",
                        value: "never"
                    }
                ]
            }
        }

        ColumnLayout {
            ContentSubsectionLabel {
                text: Translation.tr("Channel")
            }

            ConfigSelectionArray {
                currentValue: section.channel
                onSelected: newValue => WidgetsStore.setKey("errorReportsChannel", newValue)
                options: [
                    {
                        displayName: Translation.tr("ntfy"),
                        icon: "notifications",
                        value: "ntfy"
                    },
                    {
                        displayName: Translation.tr("Webhook"),
                        icon: "webhook",
                        value: "webhook"
                    },
                    {
                        displayName: Translation.tr("Command"),
                        icon: "terminal",
                        value: "command"
                    }
                ]
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 10

        MaterialTextArea {
            id: targetField
            Layout.fillWidth: true
            placeholderText: {
                switch (section.channel) {
                case "webhook":
                    return Translation.tr("URL that takes a POST");
                case "command":
                    return Translation.tr("Command reading the report on stdin");
                }
                return Translation.tr("ntfy topic URL");
            }
            text: section.target
            wrapMode: TextEdit.Wrap
            onTextChanged: {
                ErrorReporter.testState = ErrorReporter.TestState.Idle;
                commitTarget.restart();
            }

            Timer {
                id: commitTarget
                interval: 400 // Every keystroke would rewrite widgets.json
                onTriggered: WidgetsStore.setKey("errorReportsTarget", targetField.text.trim())
            }
        }

        RippleButtonWithIcon {
            Layout.alignment: Qt.AlignVCenter
            buttonRadius: Appearance.rounding.full
            enabled: section.target !== "" && ErrorReporter.testState !== ErrorReporter.TestState.Sending
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
                text: Translation.tr("Sends one report as a broken widget would")
            }
        }
    }
}
