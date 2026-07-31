pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

/**
 * Widget failure reports, sent only with consent. widgets.json keys:
 * "errorReports": "ask" | "always" | "never", "errorReportsUrl": ntfy-style endpoint.
 * No url configured - nothing is ever sent.
 */
Singleton {
    id: root
    property var reported: ({})

    function report(widgetId, message) {
        console.warn(`[ErrorReporter] ${widgetId}: ${message}`)
        const url = WidgetsStore.data.errorReportsUrl ?? ""
        const mode = WidgetsStore.data.errorReports ?? "ask"
        if (url === "" || mode === "never")
            return
        const key = `${widgetId}\n${message}`
        if (root.reported[key])
            return
        root.reported[key] = true
        if (mode === "always") {
            root.send(widgetId, message)
            return
        }
        askProc.widgetId = widgetId
        askProc.message = message
        askProc.running = true
    }

    // Logs may carry window titles and the like, hence the explicit consent
    function send(widgetId, message) {
        Quickshell.execDetached(["env", `RW=${widgetId}`, `RM=${message}`, `RU=${WidgetsStore.data.errorReportsUrl}`, "bash", "-c", `{ echo "widget: $RW"; echo "$RM"; echo; qs -c ii log 2>/dev/null | tail -100; } | curl -sf -T - -H "Title: ii widget failed: $RW" "$RU"`])
    }

    Process {
        id: askProc
        property string widgetId
        property string message
        command: ["notify-send", "-a", "Shell", "-A", "send=Send report", "-A", "never=Never", `Widget failed: ${askProc.widgetId}`, "Send the error and recent logs to the widget author?"]
        stdout: StdioCollector {
            id: answer
            onStreamFinished: {
                const a = answer.text.trim()
                if (a === "send")
                    root.send(askProc.widgetId, askProc.message)
                else if (a === "never")
                    WidgetsStore.setKey("errorReports", "never")
            }
        }
    }
}
