pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

/**
 * Widget failure reports, sent only with consent. widgets.json keys:
 * "errorReports": "ask" | "always" | "never"
 * "errorReportsChannel": "ntfy" | "webhook" | "command"
 * "errorReportsTarget": url for ntfy/webhook, shell command reading stdin for command.
 * No target configured - nothing is ever sent.
 */
Singleton {
    id: root
    property var reported: ({})
    property var askQueue: [] // notify-send is one at a time, failures are not
    property bool asking: false

    readonly property var channels: ({
        "ntfy": `curl -sf -T - -H "Title: ii widget failed: $RW" "$RT"`,
        "webhook": `jq -Rs '{widget: env.RW, report: .}' | curl -sf -X POST -H "Content-Type: application/json" -d @- "$RT"`,
        "command": `$RT`
    })

    function report(widgetId, message) {
        console.warn(`[ErrorReporter] ${widgetId}: ${message}`)
        const target = WidgetsStore.data.errorReportsTarget ?? ""
        const mode = WidgetsStore.data.errorReports ?? "ask"
        if (target === "" || mode === "never")
            return
        const key = `${widgetId}\n${message}`
        if (root.reported[key])
            return
        root.reported[key] = true
        if (mode === "always") {
            root.send(widgetId, message)
            return
        }
        root.askQueue = root.askQueue.concat([{ "widgetId": widgetId, "message": message }])
        root.askNext()
    }

    function askNext() {
        if (root.asking || root.askQueue.length === 0)
            return
        if ((WidgetsStore.data.errorReports ?? "ask") === "never") { // Answered "never" mid-queue
            root.askQueue = []
            return
        }
        root.asking = true
        askProc.widgetId = root.askQueue[0].widgetId
        askProc.message = root.askQueue[0].message
        askProc.running = true
    }

    // Logs may carry window titles and the like, hence the explicit consent
    function send(widgetId, message) {
        const pipe = root.channels[WidgetsStore.data.errorReportsChannel ?? "ntfy"]
        if (pipe === undefined)
            return
        Quickshell.execDetached(["env", `RW=${widgetId}`, `RM=${message}`, `RT=${WidgetsStore.data.errorReportsTarget}`, "bash", "-c", `{ echo "widget: $RW"; echo "$RM"; echo; qs -c ii log 2>/dev/null | tail -100; } | ${pipe}`])
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
                root.askQueue = root.askQueue.slice(1)
                root.asking = false
                askProc.running = false
                root.askNext()
            }
        }
    }
}
