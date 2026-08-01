pragma Singleton
import qs.services
import Quickshell
import Quickshell.Io
import QtQuick

/**
 * Widgets installed with git into the user widget dir: clone to add, pull to
 * update, delete the directory to remove. One job at a time, `busy` while it runs.
 */
Singleton {
    id: root

    enum State {
        Idle, Working, Done, Failed
    }

    property int state: WidgetInstaller.State.Idle
    property string message: ""
    property string job: "" // Widget id being worked on, "" for an install
    readonly property bool busy: root.state === WidgetInstaller.State.Working

    /// Directory to clone into: the repo name, ssh and https urls alike
    function idFor(url) {
        return String(url).trim().replace(/\/+$/, "").split(/[\/:]/).pop().replace(/\.git$/, "");
    }

    /// Directory name inside the widget dir, "" for anything we did not install.
    /// Names, never paths: the scripts below rebuild the path and refuse slashes
    function nameOf(widgetId) {
        const base = WidgetCatalog.externalDir === "" ? "" : `${WidgetCatalog.externalDir}/`;
        const dir = String(WidgetCatalog.widgets.find(w => w.widgetId === widgetId)?.dir ?? "").replace(/^file:\/\//, "");
        if (base === "" || !dir.startsWith(base))
            return "";
        const name = dir.slice(base.length);
        return root.sane(name) ? name : "";
    }

    function sane(name) {
        return name !== "" && !name.includes("/") && !name.startsWith(".");
    }

    function install(url) {
        const id = root.idFor(url);
        if (String(url).trim() === "" || !root.sane(id)) {
            root.fail("", Translation.tr("Enter a repository url"));
            return;
        }
        root.run("", ["env", `IU=${String(url).trim()}`, `IN=${id}`, `IW=${WidgetCatalog.externalDir}`, "bash", "-c", `
            set -e
            case "$IN" in */*|.*|"") echo "Bad repository name"; exit 1;; esac
            d="$IW/$IN"
            if [ -e "$d" ]; then echo "Already installed: $IN"; exit 1; fi
            mkdir -p "$IW"
            git clone --depth 1 -- "$IU" "$d" 2>&1
            # Only ever the directory git just made, and only when it is not a widget
            if [ ! -f "$d/Manifest.qml" ]; then rm -rf -- "$d"; echo "No Manifest.qml in $IN"; exit 1; fi
            echo "Installed $IN"`]);
    }

    function update(widgetId) {
        const name = root.nameOf(widgetId);
        if (!root.owns(widgetId, name))
            return;
        root.run(widgetId, ["env", `IN=${name}`, `IW=${WidgetCatalog.externalDir}`, "bash", "-c", `
            set -e
            case "$IN" in */*|.*|"") echo "Not a widget directory"; exit 1;; esac
            git -C "$IW/$IN" pull --ff-only 2>&1 | tail -1`]);
    }

    /// Deletes a directory, so it goes by name and only where a Manifest.qml sits
    function remove(widgetId) {
        const name = root.nameOf(widgetId);
        if (!root.owns(widgetId, name))
            return;
        WidgetsStore.setEnabled(widgetId, false); // A gone widget left enabled would come back with a reinstall
        root.run(widgetId, ["env", `IN=${name}`, `IW=${WidgetCatalog.externalDir}`, "bash", "-c", `
            set -e
            case "$IN" in */*|.*|"") echo "Not a widget directory"; exit 1;; esac
            d="$IW/$IN"
            if [ ! -f "$d/Manifest.qml" ]; then echo "Not a widget directory"; exit 1; fi
            rm -rf -- "$d"
            echo Removed`]);
    }

    /// Only ever touch directories we installed ourselves
    function owns(widgetId, name) {
        if (name !== "")
            return true;
        root.fail(widgetId, Translation.tr("%1 is not installed here").arg(widgetId));
        return false;
    }

    function fail(widgetId, message) {
        root.job = widgetId;
        root.message = message; // Before the state, whoever watches it reads the message
        root.state = WidgetInstaller.State.Failed;
    }

    function run(widgetId, command) {
        if (root.busy)
            return;
        root.job = widgetId;
        root.state = WidgetInstaller.State.Working;
        root.message = "";
        proc.command = command;
        proc.running = true;
    }

    Process {
        id: proc
        stdout: StdioCollector {
            id: output
        }
        stderr: StdioCollector {
            id: errors
        }
        onExited: exitCode => {
            // git talks in many lines and the last one says what happened
            const lines = `${output.text}\n${errors.text}`.trim().split("\n").filter(l => l.trim() !== "");
            root.message = lines.pop() ?? (exitCode === 0 ? Translation.tr("Done") : Translation.tr("git failed"));
            root.state = exitCode === 0 ? WidgetInstaller.State.Done : WidgetInstaller.State.Failed;
        }
    }
}
