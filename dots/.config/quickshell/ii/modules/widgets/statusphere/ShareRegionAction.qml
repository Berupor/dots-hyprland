import qs.modules.widgets
import QtQuick

/** Region selector action: post the selection to the room. */
QtObject {
    readonly property bool available: Statusphere.canShare

    function perform(path: string, x: real, y: real, width: real, height: real): void {
        Statusphere.postRegion(path, x, y, width, height);
    }
}
