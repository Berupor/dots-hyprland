import QtQuick
import qs.modules.widgets

Item {
    WidgetViewLoader {
        id: widgetView
        anchors.fill: parent
        slot: "catalogView"
    }

    Loader {
        anchors.fill: parent
        active: !widgetView.view
        sourceComponent: builtinView
    }

    Component {
        id: builtinView
        WidgetCatalogView {}
    }
}
