//@ probe hello -x tests/fixtures/hello -g 560x120 -s 9000
/**
 * The install lifecycle against a local repo made out of the installed fixture,
 * so the case needs git but no network: clone, pull, delete, plus the guards.
 */
import qs.modules.common
import qs.modules.widgets
import Qt.labs.folderlistmodel
import Quickshell.Io
import QtQuick

Item {
    id: probe

    // Repo name on purpose different from the widget id inside it
    readonly property string source: `${Directories.shellConfig}/installer-src/some-repo`
    property var seen: ({}) // Each step overwrites the singleton, so snapshot as they land
    property int step: 0

    function installedNames() {
        const names = [];
        for (let i = 0; i < installed.count; i++)
            names.push(String(installed.get(i, "fileName")));
        return names;
    }

    function checks() {
        return [
            {
                "name": "clone url to directory name",
                "got": ["https://github.com/u/ii-widget-foo.git", "https://github.com/u/foo/", "git@github.com:u/foo.git"].map(u => WidgetInstaller.idFor(u)),
                "want": ["ii-widget-foo", "foo", "foo"]
            },
            {
                "name": "path tricks never become directory names",
                "got": ["a/b", "..", ".git", "", "ok"].map(n => WidgetInstaller.sane(n)),
                "want": [false, false, false, false, true]
            },
            {
                "name": "a clone lands in the widget dir",
                "got": probe.seen.install ?? "",
                "want": "Installed hello-clone"
            },
            {
                "name": "the catalog picks it up with no reload",
                "got": probe.seen.installedIds?.includes("hello-clone") ?? false,
                "want": true
            },
            {
                "name": "the directory is named after the widget id, not the repo",
                "got": (probe.seen.installedDir ?? "").replace(/^.*\/widgets\//, ""),
                "want": "hello-clone"
            },
            {
                "name": "update pulls in its directory, a pull that brings nothing asks for nothing",
                "got": [probe.seen.update ?? "", probe.seen.updateReload ?? true],
                "want": ["Already up to date.", false]
            },
            {
                "name": "a new version is reported, and wants the reload it needs",
                "got": [probe.seen.bumped ?? "", probe.seen.bumpedReload ?? false],
                "want": ["Updated to 1.1", true]
            },
            {
                // By name, not by count: the run is seeded from a real config,
                // which may already have widgets of its own installed
                "name": "remove takes the directory with it",
                "got": [probe.seen.removedIds?.includes("hello-clone") ?? true, probe.installedNames().includes("hello-clone")],
                "want": [false, false]
            },
            {
                "name": "an empty url is refused",
                "got": probe.seen.emptyUrl ?? "",
                "want": "Enter a repository url"
            },
            {
                "name": "a bundled widget is not ours to remove",
                "got": probe.seen.bundled ?? "",
                "want": "androidWebcam is not installed here"
            },
            {
                "name": "and it is still in the catalog",
                "got": WidgetCatalog.widgets.map(w => w.widgetId).includes("androidWebcam"),
                "want": true
            }
        ];
    }

    FolderListModel {
        id: installed
        folder: Qt.resolvedUrl(WidgetCatalog.externalDir)
        showDirs: true
        showFiles: false
    }

    // git needs a repo to clone from, and the fixture next door is the only one
    // here. Its id is taken, hence the rename
    Process {
        id: prepare
        running: true
        command: ["env", `IS=${probe.source}`, `IH=${WidgetCatalog.externalDir}/hello`, "bash", "-c", `
            set -e
            mkdir -p "$(dirname "$IS")"
            cp -r "$IH" "$IS"
            sed -i 's/widgetId: "hello"/widgetId: "hello-clone"/' "$IS/Manifest.qml"
            git -C "$IS" init -q
            git -C "$IS" add -A
            git -C "$IS" -c user.email=t@t -c user.name=t commit -qm fixture`]
        onExited: exitCode => {
            if (exitCode !== 0) {
                probe.seen = Object.assign({}, probe.seen, { "install": "prepare failed" });
                return;
            }
            WidgetInstaller.install(probe.source);
        }
    }

    Process {
        id: bump
        command: ["env", `IS=${probe.source}`, "bash", "-c", `
            set -e
            sed -i 's/^\\([[:space:]]*\\)version: "1.0"/\\1version: "1.1"/' "$IS/Manifest.qml"
            git -C "$IS" -c user.email=t@t -c user.name=t commit -aqm bump`]
        onExited: WidgetInstaller.update("hello-clone")
    }

    Connections {
        target: WidgetInstaller
        function onStateChanged() {
            if (WidgetInstaller.state === WidgetInstaller.State.Working)
                return;
            const snap = {};
            switch (probe.step) {
            case 0:
                snap.install = WidgetInstaller.message;
                break;
            case 1:
                snap.update = WidgetInstaller.message;
                snap.updateReload = WidgetInstaller.needsReload;
                break;
            case 2:
                snap.bumped = WidgetInstaller.message;
                snap.bumpedReload = WidgetInstaller.needsReload;
                break;
            }
            probe.seen = Object.assign({}, probe.seen, snap);
            probe.step++;
            next.restart();
        }
    }

    Timer {
        id: next
        interval: 400 // The catalog rescans on its own, give it that long to land
        onTriggered: {
            const ids = WidgetCatalog.widgets.map(w => w.widgetId);
            switch (probe.step) {
            case 1:
                probe.seen = Object.assign({}, probe.seen, {
                    "installedIds": ids,
                    "installedDir": String(WidgetCatalog.widgets.find(w => w.widgetId === "hello-clone")?.dir ?? "")
                });
                WidgetInstaller.update("hello-clone");
                break;
            case 2:
                bump.running = true; // A pull that brings a new version reads differently
                break;
            case 3:
                WidgetInstaller.remove("hello-clone");
                break;
            case 4:
                // Refusals answer on the spot, and two in a row leave the state
                // unchanged, so read the message instead of waiting for a signal
                WidgetInstaller.install("   ");
                const emptyUrl = WidgetInstaller.message;
                WidgetInstaller.remove("androidWebcam");
                probe.seen = Object.assign({}, probe.seen, { "removedIds": ids, "emptyUrl": emptyUrl, "bundled": WidgetInstaller.message });
                break;
            }
        }
    }
}
