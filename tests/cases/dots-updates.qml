//@ probe dotsUpdates -g 320x200 -s 3000 -o repoPath= -o notify=true
/**
 * Update notifications: when the same batch is offered again and when it is not.
 * An empty repoPath keeps the poller off, so the state stays what the case sets.
 */
import qs.modules.widgets
import QtQuick

Item {
    id: probe
    property var snap: ({})

    function checks() {
        return [
            {
                "name": "nothing to offer while not behind",
                "got": probe.snap.noCommits ?? true,
                "want": false
            },
            {
                "name": "a fresh batch is offered",
                "got": probe.snap.fresh ?? false,
                "want": true
            },
            {
                "name": "the same batch is not offered twice in a day",
                "got": probe.snap.again ?? true,
                "want": false
            },
            {
                "name": "an ignored batch comes back a day later",
                "got": probe.snap.nextDay ?? false,
                "want": true
            },
            {
                "name": "a skipped batch never comes back",
                "got": probe.snap.skipped ?? true,
                "want": false
            },
            {
                "name": "notifications off silence a fresh batch",
                "got": probe.snap.off ?? true,
                "want": false
            }
        ];
    }

    Timer { // Not onCompleted: the store loads its file asynchronously
        running: true
        interval: 800
        onTriggered: {
            const s = {};
            DotsUpdates.remoteSha = "aaa";
            DotsUpdates.behind = 0;
            s.noCommits = DotsUpdates.shouldNotify();
            DotsUpdates.behind = 3;
            s.fresh = DotsUpdates.shouldNotify();
            DotsUpdates.setOpt("notifiedSha", "aaa");
            DotsUpdates.setOpt("notifiedAt", Date.now());
            s.again = DotsUpdates.shouldNotify();
            DotsUpdates.setOpt("notifiedAt", Date.now() - 25 * 3600000);
            s.nextDay = DotsUpdates.shouldNotify();
            DotsUpdates.setOpt("dismissedSha", "aaa");
            s.skipped = DotsUpdates.shouldNotify();
            DotsUpdates.setOpt("dismissedSha", "");
            DotsUpdates.setOpt("notify", false);
            s.off = DotsUpdates.shouldNotify();
            probe.snap = s;
        }
    }
}
