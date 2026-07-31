import qs.modules.widgets
import qs.services

WidgetManifest {
    widgetId: "gpu"
    name: Translation.tr("GPU monitor")
    description: Translation.tr("Load, VRAM and temperature in the bar resources group")
    icon: "deployed_code"
    available: GpuStatus.available
    options: [
        { "key": "hotTemp", "type": "spinBox", "icon": "thermostat", "label": Translation.tr("Hot temperature (°C)"), "default": 95, "min": 40, "max": 120, "step": 5 }
    ]
}
