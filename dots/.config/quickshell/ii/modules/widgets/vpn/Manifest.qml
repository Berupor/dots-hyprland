import qs.modules.widgets
import qs.services

WidgetManifest {
    widgetId: "vpn"
    name: Translation.tr("VPN")
    description: Translation.tr("Toggle and inspect VPN connections")
    icon: "vpn_lock"
    available: VpnStatus.available // The cli lives outside PATH, the service checks it
    slots: ({ "barUtilButton": "VpnButton.qml" })
}
