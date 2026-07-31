pragma Singleton

import qs.modules.common
import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string killDialogQmlPath: FileUtils.trimFileProtocol(Quickshell.shellPath("killDialog.qml"))

    function load() {
        // dummy to force init
    }

    Connections {
        target: Config
        function onReadyChanged() {
            if (Config.ready) checkConflictsProc.running = true
        }
    }

    Process {
        id: checkConflictsProc
        // A tray conflicts only when it owns the watcher name, not whenever kded6 runs
        command: ["bash", "-c", `echo "$(busctl --user status org.kde.StatusNotifierWatcher 2>/dev/null | awk -F= '/^Comm=/ && $2 != "qs" && $2 != "quickshell" { print $2 }');$(pidof mako dunst)"`]
        stdout: StdioCollector {
            onStreamFinished: {
                const output = this.text;
                const conflictingTrays = output.split(";")[0].trim().length > 0;
                const conflictingNotifications = output.split(";")[1].trim().length > 0;
                var openDialog = false;
                if (conflictingTrays) {
                    if (!Config.options.conflictKiller.autoKillTrays) openDialog = true;
                    else Quickshell.execDetached(["killall", "kded6"])
                }
                if (conflictingNotifications) {
                    if (!Config.options.conflictKiller.autoKillNotificationDaemons) openDialog = true;
                    else Quickshell.execDetached(["killall", "mako", "dunst"])
                }
                if (openDialog) {
                    Quickshell.execDetached(["qs", "-p", root.killDialogQmlPath])
                }
            }
        }
    }
}
