import qs.modules.widgets
import qs.services

WidgetManifest {
    widgetId: "peripheralBattery"
    name: Translation.tr("Peripheral battery")
    description: Translation.tr("Battery of mice, keyboards, headsets and other bluetooth stuff")
    icon: "battery_android_full"
    options: [
        { "key": "showAll", "type": "switch", "icon": "devices_other", "label": Translation.tr("Every device, not just the emptiest one"), "default": true },
        { "key": "sidebarTab", "type": "switch", "icon": "dock_to_left", "label": Translation.tr("Tab in the right sidebar"), "default": true }
    ]
    slots: {
        const s = { "barIndicator": "PeripheralBatteryIndicator.qml" };
        if (WidgetsStore.data.options?.peripheralBattery?.sidebarTab ?? true)
            s.sidebarRightTab = { "name": Translation.tr("Devices"), "icon": "battery_android_full", "path": "PeripheralBatteryTab.qml" };
        return s;
    }
}
