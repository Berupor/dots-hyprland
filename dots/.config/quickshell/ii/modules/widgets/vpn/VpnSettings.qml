import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.widgets

ColumnLayout {
    ContentSubsection {
        title: Translation.tr("OpenVPN profiles")

        MaterialTextField {
            id: dirField
            Layout.fillWidth: true
            placeholderText: "~/vpn"
            text: WidgetCatalog.option("vpn", "ovpnDir") ?? ""
            onTextChanged: commitDir.restart()

            Timer {
                id: commitDir
                interval: 400 // Every keystroke would rewrite widgets.json
                onTriggered: WidgetsStore.setOption("vpn", "ovpnDir", dirField.text.trim())
            }
        }

        StyledText {
            Layout.fillWidth: true
            Layout.leftMargin: 2
            text: Translation.tr("Every .ovpn file in this folder becomes a profile (nmcli connection import). Empty means profiles are whatever's already imported into NetworkManager.")
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Appearance.colors.colSubtext
            wrapMode: Text.WordWrap
        }
    }
}
