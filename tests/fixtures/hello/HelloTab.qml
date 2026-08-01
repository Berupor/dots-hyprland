import qs.modules.common
import qs.modules.common.widgets
import QtQuick

/** Sidebar tab of the fixture: a slot the host builds by hand, not through a Loader. */
Item {
    readonly property string greeting: HelloState.greeting

    StyledText {
        anchors.centerIn: parent
        text: HelloState.greeting
        color: Appearance.colors.colOnLayer1
    }
}
