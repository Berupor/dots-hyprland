pragma Singleton
pragma ComponentBehavior: Bound

import qs.services
import qs.modules.common
import Quickshell
import Quickshell.Services.UPower
import QtQuick

/**
 * Battery of peripherals: mice and keyboards (hid++/solaar), headsets, other bluetooth stuff.
 * Separate from Battery.qml, which is about the machine's own battery and is off on a desktop.
 */
Singleton {
    id: root

    readonly property real lowThreshold: Config.options.battery.low / 100
    // Hysteresis: clear the "already warned" mark well above the threshold
    readonly property real clearThreshold: root.lowThreshold + 0.05

    /**
     * Anything that doesn't power the machine itself. Keyed on powerSupply: false
     * (true for laptop batteries and UPSes), so devices with an unknown type are kept too.
     */
    readonly property var devices: {
        const result = [];
        const all = UPower.devices?.values ?? [];
        for (let i = 0; i < all.length; ++i) {
            const dev = all[i];
            if (!dev || !dev.ready)
                continue;
            if (dev.powerSupply || dev.isLaptopBattery)
                continue;
            if (dev.type === UPowerDeviceType.LinePower)
                continue;
            if (!dev.isPresent)
                continue;
            result.push(dev);
        }
        // Emptiest first, that's the one the bar shows
        result.sort((a, b) => a.percentage - b.percentage);
        return result;
    }

    readonly property int count: root.devices.length

    // nativePath -> true once warned about low battery, plain bookkeeping, not reactive
    property var notified: ({})

    function isLow(dev): bool {
        return !!dev && dev.percentage <= root.lowThreshold && dev.state !== UPowerDeviceState.Charging;
    }

    function isCharging(dev): bool {
        return !!dev && (dev.state === UPowerDeviceState.Charging || dev.state === UPowerDeviceState.PendingCharge);
    }

    function nameFor(dev): string {
        if (!dev)
            return "";
        if (dev.model && dev.model.length > 0)
            return dev.model;
        if (dev.nativePath && dev.nativePath.length > 0)
            return dev.nativePath;
        return UPowerDeviceType.toString(dev.type);
    }

    function iconFor(type: int): string {
        switch (type) {
        case UPowerDeviceType.Mouse:
            return "mouse";
        case UPowerDeviceType.Keyboard:
            return "keyboard";
        case UPowerDeviceType.Headset:
        case UPowerDeviceType.Headphones:
            return "headphones";
        case UPowerDeviceType.Speakers:
        case UPowerDeviceType.OtherAudio:
            return "speaker";
        case UPowerDeviceType.GamingInput:
            return "videogame_asset";
        case UPowerDeviceType.Pen:
            return "stylus_note";
        case UPowerDeviceType.Touchpad:
            return "touch_app";
        case UPowerDeviceType.Tablet:
        case UPowerDeviceType.Pda:
        case UPowerDeviceType.Phone:
            return "tablet_mac";
        case UPowerDeviceType.Wearable:
            return "watch";
        default:
            return "devices_other";
        }
    }

    function stateString(dev): string {
        if (!dev)
            return "";
        switch (dev.state) {
        case UPowerDeviceState.Charging:
            return Translation.tr("Charging");
        case UPowerDeviceState.Discharging:
            return Translation.tr("Discharging");
        case UPowerDeviceState.FullyCharged:
            return Translation.tr("Full");
        case UPowerDeviceState.PendingCharge:
            return Translation.tr("Pending charge");
        case UPowerDeviceState.PendingDischarge:
            return Translation.tr("Pending discharge");
        case UPowerDeviceState.Empty:
            return Translation.tr("Empty");
        default:
            return Translation.tr("Unknown");
        }
    }

    function durationString(seconds: real): string {
        const hours = Math.floor(seconds / 3600);
        const minutes = Math.floor((seconds % 3600) / 60);
        return hours > 0 ? Translation.tr("%1 h %2 min").arg(hours).arg(minutes) : Translation.tr("%1 min").arg(minutes);
    }

    /** State and time left, both only when UPower knows them. Empty when it knows neither. */
    function detailFor(dev): string {
        if (!dev)
            return "";
        const parts = [];
        if (dev.state !== UPowerDeviceState.Unknown)
            parts.push(root.stateString(dev));
        if (dev.timeToEmpty > 0)
            parts.push(Translation.tr("%1 left").arg(root.durationString(dev.timeToEmpty)));
        else if (dev.timeToFull > 0)
            parts.push(Translation.tr("%1 until full").arg(root.durationString(dev.timeToFull)));
        return parts.join(" · ");
    }

    function checkLow(): void {
        const marks = root.notified;
        for (let i = 0; i < root.devices.length; ++i) {
            const dev = root.devices[i];
            const key = dev.nativePath || root.nameFor(dev);
            if (root.isLow(dev)) {
                if (marks[key])
                    continue;
                marks[key] = true;
                Quickshell.execDetached(["notify-send", Translation.tr("%1 battery low").arg(root.nameFor(dev)), Translation.tr("%1% left — time to charge it").arg(Math.round(dev.percentage * 100)), "-u", "critical", "-a", "Shell", "-i", "battery-caution-symbolic", "--hint=int:transient:1"]);
            } else if (marks[key] && (root.isCharging(dev) || dev.percentage >= root.clearThreshold)) {
                delete marks[key];
            }
        }
    }

    onDevicesChanged: root.checkLow()
}
