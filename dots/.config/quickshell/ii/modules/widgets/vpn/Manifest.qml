import qs.modules.widgets
import qs.services

WidgetManifest {
    widgetId: "vpn"
    name: Translation.tr("VPN")
    description: Translation.tr("Toggle and inspect VPN connections")
    icon: "vpn_lock"
    available: VpnStatus.available // nmcli is the hard requirement, tailscale is optional
    slots: ({ "barUtilButton": "VpnButton.qml" })
    options: [
        { key: "ovpnDir", default: "" } // No label: text input, rendered by settingsPage
    ]
    settingsPage: "VpnSettings.qml"
}
