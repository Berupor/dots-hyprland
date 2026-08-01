import QtQuick

/** Region action of the fixture: takes the region and records what it got. */
QtObject {
    id: root

    property bool available: true
    property string lastRegion: ""

    function perform(path: string, x: real, y: real, width: real, height: real): void {
        root.lastRegion = `${path} ${x},${y} ${width}x${height}`;
    }
}
