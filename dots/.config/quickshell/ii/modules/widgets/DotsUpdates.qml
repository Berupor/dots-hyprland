pragma Singleton
pragma ComponentBehavior: Bound

// New commits on the dots checkout, pulled through the installer on demand.

import qs.modules.common
import qs.modules.common.functions
import qs.services
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    enum Status {
        Idle, Checking, UpToDate, Behind, NoRepo, NoUpstream, FetchFailed
    }

    readonly property string rawPath: (root.opt("repoPath") ?? "").trim()
    readonly property string repoPath: rawPath.startsWith("~/") ? `${FileUtils.trimFileProtocol(Directories.home)}/${rawPath.slice(2)}` : rawPath

    property int state: DotsUpdates.Status.Idle
    property string branch: ""
    property string remoteSha: ""
    property int behind: 0
    property var commits: [] // Subjects, newest first, capped at 20
    property double lastCheck: 0
    property bool discardRun: false

    readonly property bool hasUpdates: root.behind > 0
    readonly property bool checking: root.state === DotsUpdates.Status.Checking
    readonly property int remindHours: 24

    function opt(key: string): var {
        return WidgetCatalog.option("dotsUpdates", key);
    }

    function setOpt(key: string, value: var): void {
        WidgetsStore.setOption("dotsUpdates", key, value);
    }

    function check(): void {
        if (root.repoPath === "")
            return;
        root.state = DotsUpdates.Status.Checking;
        if (checkProc.running) { // Its exit belongs to the path it started with
            root.discardRun = true;
            checkProc.running = false;
        }
        checkProc.running = true;
    }

    // A terminal, not a silent rsync: a diverged branch or edits in the checkout must
    // be seen, and install-files replaces the config the shell is running from
    function update(): void {
        if (root.repoPath === "")
            return;
        const script = `cd "${root.repoPath}" && git pull --ff-only && ./setup install-files -f; echo; read -rp "Press enter to close"`;
        Quickshell.execDetached(["env", `DU_CMD=${script}`, "bash", "-c", `${Config.options.apps.terminal} -e bash -c "$DU_CMD"`]);
        followup.restart();
    }

    function sinceString(timestamp: double): string {
        if (timestamp === 0)
            return Translation.tr("never");
        const minutes = Math.floor((Date.now() - timestamp) / 60000);
        if (minutes < 1)
            return Translation.tr("just now");
        if (minutes < 60)
            return Translation.tr("%1m ago").arg(minutes);
        return Translation.tr("%1h ago").arg(Math.floor(minutes / 60));
    }

    onRepoPathChanged: root.check()

    Process {
        id: checkProc
        command: ["env", `DU_PATH=${root.repoPath}`, "bash", "-c", `cd "$DU_PATH" 2>/dev/null || exit 3
git rev-parse --git-dir >/dev/null 2>&1 || exit 3
git rev-parse @{u} >/dev/null 2>&1 || exit 5
git fetch --quiet --no-tags || exit 4
git rev-parse --abbrev-ref HEAD
git rev-parse @{u}
git rev-list --count HEAD..@{u}
git log --format=%s -n 20 HEAD..@{u}`]

        stdout: StdioCollector {
            id: checkCollector
            onStreamFinished: {
                const lines = checkCollector.text.split("\n");
                if (lines.length < 3)
                    return; // Failed run, the exit code tells why
                root.branch = lines[0];
                root.remoteSha = lines[1];
                root.behind = parseInt(lines[2]) || 0;
                root.commits = lines.slice(3).filter(l => l !== "");
                root.state = root.behind > 0 ? DotsUpdates.Status.Behind : DotsUpdates.Status.UpToDate;
                root.maybeNotify();
            }
        }

        onExited: exitCode => {
            if (root.discardRun) {
                root.discardRun = false;
                return;
            }
            root.lastCheck = Date.now();
            if (exitCode === 0)
                return;
            root.behind = 0;
            root.commits = [];
            root.state = exitCode === 3 ? DotsUpdates.Status.NoRepo : exitCode === 5 ? DotsUpdates.Status.NoUpstream : DotsUpdates.Status.FetchFailed;
        }
    }

    /// Ignored batches come back the next day, declined ones never again
    function shouldNotify(): bool {
        if (!root.opt("notify") || root.behind === 0 || notifyProc.running)
            return false;
        if (root.opt("dismissedSha") === root.remoteSha)
            return false;
        if (root.opt("notifiedSha") !== root.remoteSha)
            return true;
        return Date.now() - (root.opt("notifiedAt") ?? 0) >= root.remindHours * 3600000;
    }

    function maybeNotify(): void {
        if (!root.shouldNotify())
            return;
        root.setOpt("notifiedSha", root.remoteSha);
        root.setOpt("notifiedAt", Date.now());
        notifyProc.sha = root.remoteSha;
        notifyProc.running = true;
    }

    Process {
        id: notifyProc
        property string sha: ""
        command: ["notify-send", "-a", "Shell", "-A", "update=Update", "-A", "skip=Skip", Translation.tr("Dots updates available"), root.behind === 1 ? Translation.tr("1 new commit on %1").arg(root.branch) : Translation.tr("%1 new commits on %2").arg(root.behind).arg(root.branch)]

        stdout: StdioCollector {
            id: answer
            onStreamFinished: {
                const a = answer.text.trim();
                if (a === "update")
                    root.update();
                else if (a === "skip")
                    root.setOpt("dismissedSha", notifyProc.sha);
                notifyProc.running = false;
            }
        }
    }

    Timer {
        interval: Math.max(5, root.opt("checkMinutes") ?? 60) * 60000
        running: WidgetCatalog.isEnabled("dotsUpdates") && root.repoPath !== ""
        repeat: true
        triggeredOnStart: true
        onTriggered: root.check()
    }

    // The pull runs in a terminal we don't wait on, so catch up on its result
    Timer {
        id: followup
        interval: 20000
        repeat: true
        property int n: 0
        onRunningChanged: if (running)
            n = 0
        onTriggered: {
            root.check();
            if (++n >= 8)
                stop();
        }
    }
}
