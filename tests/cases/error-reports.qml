//@ probe -g 620x220 -s 3000 -K errorReports=always -K errorReportsChannel=command -K errorReportsTarget=cat
/**
 * Error report settings: store to section, and both outcomes of a test send.
 * Flags are word-split by the runner, hence targets without spaces: `cat` exits
 * 0, a POST to the discard port cannot connect.
 */
import qs.modules.widgets
import QtQuick

Item {
    id: probe
    property var seen: []
    property var snap: ({}) // The second send rewrites the store, so keep the first state

    function checks() {
        return [
            {
                "name": "section shows the stored mode",
                "got": probe.snap.mode ?? "",
                "want": "always"
            },
            {
                "name": "section shows the stored channel",
                "got": probe.snap.channel ?? "",
                "want": "command"
            },
            {
                "name": "section shows the stored target",
                "got": probe.snap.target ?? "",
                "want": "cat"
            },
            {
                "name": "target reaches the pipe environment",
                "got": probe.snap.argv?.indexOf("RT=cat") ?? -1,
                "want": 3
            },
            {
                "name": "channel pipe ends the command",
                "got": probe.snap.argv?.[probe.snap.argv.length - 1]?.endsWith("| $RT") ?? false,
                "want": true
            },
            {
                "name": "a delivered test send is seen",
                "got": probe.seen.indexOf(ErrorReporter.TestState.Sent) >= 0,
                "want": true
            },
            {
                "name": "an unreachable target fails the test send",
                "got": ErrorReporter.testState,
                "want": ErrorReporter.TestState.Failed
            }
        ];
    }

    ErrorReportsSection {
        id: section
        width: probe.width
    }

    Connections {
        target: ErrorReporter
        function onTestStateChanged() {
            probe.seen = probe.seen.concat([ErrorReporter.testState]);
        }
    }

    Timer { // Not onCompleted: the store loads its file asynchronously
        running: true
        interval: 800
        onTriggered: {
            probe.snap = {
                "mode": section.mode,
                "channel": section.channel,
                "target": section.target,
                "argv": ErrorReporter.argv("test", "hello")
            };
            ErrorReporter.test();
        }
    }

    Timer {
        running: true
        interval: 1800
        onTriggered: {
            WidgetsStore.setKey("errorReportsChannel", "webhook");
            WidgetsStore.setKey("errorReportsTarget", "http://127.0.0.1:9/hook");
            ErrorReporter.test();
        }
    }
}
