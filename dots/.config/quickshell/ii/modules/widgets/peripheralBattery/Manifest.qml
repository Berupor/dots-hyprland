import qs.modules.widgets
import qs.services

WidgetManifest {
    widgetId: "peripheralBattery"
    name: Translation.tr("Peripheral battery")
    description: Translation.tr("Battery of mice, keyboards, headsets and other bluetooth stuff")
    icon: "battery_android_full"
    options: [
        { "key": "showAll", "type": "switch", "icon": "devices_other", "label": Translation.tr("Every device, not just the emptiest one"), "default": true },
        { "key": "barIndicator", "type": "switch", "icon": "toolbar", "label": Translation.tr("Indicator in the top bar"), "default": true },
        { "key": "sidebarTab", "type": "switch", "icon": "dock_to_left", "label": Translation.tr("Tab in the right sidebar"), "default": true }
    ]
    slots: {
        const s = {};
        if (optionValue("barIndicator"))
            s.barIndicator = "PeripheralBatteryIndicator.qml";
        if (optionValue("sidebarTab"))
            s.sidebarRightTab = { "name": Translation.tr("Devices"), "icon": "battery_android_full", "path": "PeripheralBatteryTab.qml" };
        return s;
    }
}
