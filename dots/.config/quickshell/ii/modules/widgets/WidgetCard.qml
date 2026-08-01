import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.widgets

/**
 * One catalog widget: switch list item, options behind a disclosure.
 */
Rectangle {
    id: root
    required property var manifest
    readonly property bool widgetEnabled: WidgetCatalog.isEnabled(manifest.widgetId)
    readonly property var drawnOptions: manifest.options.filter(o => o.label) // The rest are values for a settingsPage
    readonly property bool hasBody: root.drawnOptions.length > 0 || manifest.settingsPage !== "" || root.placements.length > 0
    readonly property bool bodyShown: root.widgetEnabled && root.hasBody && root.expanded
    property bool expanded: false

    readonly property var slotNames: ({
        "barUtilButton": Translation.tr("Bar button"),
        "barIndicator": Translation.tr("Bar indicator"),
        "sidebarLeftTab": Translation.tr("Left sidebar"),
        "sidebarRightTab": Translation.tr("Right sidebar"),
        "backgroundWidget": Translation.tr("Wallpaper"),
        "regionAction": Translation.tr("Region selector"),
        "catalogView": Translation.tr("This page"),
        "settingsView": Translation.tr("Settings window")
    })
    readonly property var placements: Object.keys(root.manifest.slots).map(s => root.slotNames[s] ?? s)

    /// Where an installed widget sits, so it is clear what to update or delete by hand
    readonly property string originText: {
        const path = FileUtils.trimFileProtocol(String(root.manifest.dir)).replace(FileUtils.trimFileProtocol(Directories.home), "~");
        const by = [root.manifest.author, root.manifest.version].filter(s => s !== "").join(" · ");
        return Translation.tr("Installed in %1").arg(path) + (by === "" ? "" : `\n${by}`);
    }

    Layout.fillWidth: true
    implicitHeight: cardColumn.implicitHeight
    radius: Appearance.rounding.large
    color: Appearance.colors.colLayer3

    component PlacementChip: Rectangle {
        property string label
        implicitWidth: chipText.implicitWidth + 22
        implicitHeight: 26
        radius: Appearance.rounding.full
        color: "transparent"
        border.width: 1
        border.color: Appearance.colors.colOutlineVariant

        StyledText {
            id: chipText
            anchors.centerIn: parent
            text: parent.label
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Appearance.colors.colOnSurfaceVariant
        }
    }

    ColumnLayout {
        id: cardColumn
        width: parent.width
        spacing: 0

        Item { // Header
            Layout.fillWidth: true
            implicitHeight: headerRow.implicitHeight + 12 * 2

            Rectangle {
                anchors.fill: parent
                radius: root.radius
                color: Appearance.colors.colOnLayer2
                opacity: headerArea.containsMouse ? 0.06 : 0
                Behavior on opacity {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
            }

            MouseArea {
                id: headerArea
                anchors.fill: parent
                hoverEnabled: true
                enabled: root.widgetEnabled && root.hasBody
                cursorShape: Qt.PointingHandCursor
                onClicked: root.expanded = !root.expanded
            }

            RowLayout {
                id: headerRow
                anchors {
                    left: parent.left
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                    leftMargin: 14
                    rightMargin: 14
                }
                spacing: 14

                MaterialShapeWrappedMaterialSymbol {
                    Layout.alignment: Qt.AlignVCenter
                    text: root.manifest.icon
                    iconSize: Appearance.font.pixelSize.hugeass
                    padding: 10
                    opacity: root.manifest.available ? 1 : 0.4
                    color: root.widgetEnabled ? Appearance.colors.colPrimary : Appearance.colors.colSurfaceContainerHighest
                    colSymbol: root.widgetEnabled ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSurfaceVariant

                    Behavior on color {
                        animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    StyledText {
                        Layout.fillWidth: true
                        text: root.manifest.name
                        font.pixelSize: Appearance.font.pixelSize.large
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnLayer2
                        elide: Text.ElideRight
                        opacity: root.manifest.available ? 1 : 0.6
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: {
                            if (root.manifest.depsMissing.length > 0)
                                return Translation.tr("Needs %1").arg(root.manifest.depsMissing.join(", "));
                            if (!root.manifest.available)
                                return Translation.tr("Not available on this system");
                            return root.manifest.description;
                        }
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: root.manifest.available ? Appearance.colors.colSubtext : Appearance.colors.colError
                        wrapMode: Text.WordWrap
                    }
                }

                MaterialSymbol {
                    Layout.alignment: Qt.AlignVCenter
                    visible: root.manifest.external
                    text: "folder_open"
                    iconSize: Appearance.font.pixelSize.larger
                    color: Appearance.colors.colOnSurfaceVariant

                    HoverHandler {
                        id: originHover
                    }

                    StyledToolTip {
                        extraVisibleCondition: false
                        alternativeVisibleCondition: originHover.hovered
                        text: root.originText
                    }
                }

                MaterialSymbol {
                    Layout.alignment: Qt.AlignVCenter
                    opacity: (root.widgetEnabled && root.hasBody) ? 1 : 0
                    text: "keyboard_arrow_down"
                    iconSize: Appearance.font.pixelSize.huge
                    color: Appearance.colors.colOnSurfaceVariant
                    rotation: root.expanded ? 180 : 0

                    Behavior on rotation {
                        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                    }
                    Behavior on opacity {
                        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                    }
                }

                StyledSwitch {
                    Layout.alignment: Qt.AlignVCenter
                    enabled: root.manifest.available
                    checked: root.widgetEnabled
                    onClicked: {
                        WidgetsStore.setEnabled(root.manifest.widgetId, checked);
                        root.expanded = checked; // Just switched on, so show what's inside
                    }
                }
            }
        }

        Item { // Body
            Layout.fillWidth: true
            clip: true
            implicitHeight: root.bodyShown ? bodyColumn.implicitHeight : 0
            visible: implicitHeight > 0

            Behavior on implicitHeight {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }

            ColumnLayout {
                id: bodyColumn
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    leftMargin: 10
                    rightMargin: 10
                }
                spacing: 2

                Rectangle {
                    Layout.fillWidth: true
                    Layout.bottomMargin: 8
                    implicitHeight: 1
                    color: Appearance.colors.colOutlineVariant
                }

                RowLayout {
                    visible: root.placements.length > 0
                    Layout.leftMargin: 8
                    Layout.bottomMargin: 6
                    spacing: 6

                    Repeater {
                        model: root.placements
                        delegate: PlacementChip {
                            required property string modelData
                            label: modelData
                        }
                    }
                }

                Repeater {
                    model: root.bodyShown ? root.drawnOptions : []
                    delegate: Loader {
                        id: optLoader
                        required property var modelData
                        readonly property Component control: {
                            switch (modelData.type) {
                            case "switch": return switchOption;
                            case "spinBox": return spinOption;
                            }
                            return null;
                        }
                        Layout.fillWidth: true
                        sourceComponent: control
                        Component.onCompleted: if (!control) ErrorReporter.report(root.manifest.widgetId, `Unknown option type "${modelData.type}" for "${modelData.key}"`)

                        Component {
                            id: switchOption
                            ConfigSwitch {
                                buttonIcon: optLoader.modelData.icon ?? ""
                                text: optLoader.modelData.label
                                checked: root.manifest.optionValue(optLoader.modelData.key) ?? false
                                onCheckedChanged: WidgetsStore.setOption(root.manifest.widgetId, optLoader.modelData.key, checked)
                            }
                        }
                        Component {
                            id: spinOption
                            ConfigSpinBox {
                                icon: optLoader.modelData.icon ?? ""
                                text: optLoader.modelData.label
                                value: root.manifest.optionValue(optLoader.modelData.key) ?? 0
                                from: optLoader.modelData.min ?? 0
                                to: optLoader.modelData.max ?? 100
                                stepSize: optLoader.modelData.step ?? 1
                                onValueChanged: WidgetsStore.setOption(root.manifest.widgetId, optLoader.modelData.key, value)
                            }
                        }
                    }
                }

                Loader {
                    Layout.fillWidth: true
                    active: root.bodyShown && root.manifest.settingsPage !== ""
                    source: active ? root.manifest.resolve(root.manifest.settingsPage) : ""
                }

                Item {
                    implicitHeight: 8
                }
            }
        }
    }
}
