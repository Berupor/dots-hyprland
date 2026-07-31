import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    property int currentIndex: 0
    property bool expanded: false
    default property alias tabData: tabBarColumn.data  
    implicitHeight: tabBarColumn.implicitHeight
    implicitWidth: tabBarColumn.implicitWidth
    Layout.topMargin: 25

    // A Repeater sits among the buttons in children, so indices there aren't tab indices
    readonly property var buttons: {
        const result = [];
        for (let i = 0; i < tabBarColumn.children.length; i++) {
            const child = tabBarColumn.children[i];
            if (child?.baseSize !== undefined)
                result.push(child);
        }
        return result;
    }
    readonly property Item currentButton: root.buttons[root.currentIndex] ?? null

    Rectangle {
        property real itemHeight: root.currentButton?.baseSize ?? 56
        property real baseHighlightHeight: root.currentButton?.baseHighlightHeight ?? 32
        anchors {
            top: tabBarColumn.top
            left: tabBarColumn.left
            topMargin: itemHeight * root.currentIndex + (root.expanded ? 0 : ((itemHeight - baseHighlightHeight) / 2))
        }
        radius: Appearance.rounding.full
        color: Appearance.colors.colSecondaryContainer
        implicitHeight: root.expanded ? itemHeight : baseHighlightHeight
        implicitWidth: root.currentButton?.visualWidth ?? itemHeight

        Behavior on anchors.topMargin {
            NumberAnimation {
                duration: Appearance.animationCurves.expressiveFastSpatialDuration
                easing.type: Appearance.animation.elementMove.type
                easing.bezierCurve: Appearance.animationCurves.expressiveFastSpatial
            }
        }
    }

    ColumnLayout {
        id: tabBarColumn
        anchors.fill: parent
        spacing: 0
    }
}
