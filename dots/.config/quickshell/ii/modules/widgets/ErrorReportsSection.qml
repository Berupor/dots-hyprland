import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.widgets

/**
 * Where widget failure reports go. Keys are documented in ErrorReporter.
 * Only the webhook channel is offered here; ntfy and command stay hand-edited.
 */
ContentSection {
    id: section
    readonly property string mode: WidgetsStore.data.errorReports ?? "ask"
    readonly property string target: WidgetsStore.data.errorReportsTarget ?? ""

    icon: "bug_report"
    title: Translation.tr("Error reports")

    NoticeBox {
        Layout.fillWidth: true
        materialIcon: "policy"
        text: Translation.tr("A failing widget can send its error along with the last 100 log lines. Logs carry window titles and paths, so nothing is sent until a target is set here.")
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.topMargin: 4
        spacing: 4

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
        Layout.fillWidth: true
        Layout.topMargin: 10
        spacing: 4

        ContentSubsectionLabel {
            text: Translation.tr("Where they go")
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            MaterialTextArea {
                id: targetField
                Layout.fillWidth: true
                placeholderText: Translation.tr("URL that takes a POST")
                text: section.target
                wrapMode: TextEdit.WrapAnywhere // A URL has nowhere to break by words
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
}
