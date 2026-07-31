import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.widgets

ContentPage {
    forceWidth: true

    Repeater {
        model: WidgetCatalog.widgets
        delegate: ContentSection {
            id: section
            required property var modelData
            icon: modelData.icon
            title: modelData.name

            ConfigSwitch {
                buttonIcon: "check"
                text: section.modelData.description
                enabled: section.modelData.available
                checked: WidgetCatalog.isEnabled(section.modelData.widgetId)
                onCheckedChanged: WidgetsStore.setEnabled(section.modelData.widgetId, checked)
                StyledToolTip {
                    extraVisibleCondition: section.modelData.depsMissing.length > 0
                    text: Translation.tr("Requires: %1").arg(section.modelData.depsMissing.join(", "))
                }
            }

            StyledText {
                visible: section.modelData.depsMissing.length > 0
                text: Translation.tr("Missing: %1").arg(section.modelData.depsMissing.join(", "))
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colError
            }

            Repeater {
                model: WidgetCatalog.isEnabled(section.modelData.widgetId) ? section.modelData.options : []
                delegate: Loader {
                    id: optLoader
                    required property var modelData
                    Layout.fillWidth: true
                    sourceComponent: modelData.type === "spinBox" ? spinOption : switchOption

                    Component {
                        id: switchOption
                        ConfigSwitch {
                            buttonIcon: optLoader.modelData.icon ?? ""
                            text: optLoader.modelData.label
                            checked: WidgetCatalog.option(section.modelData.widgetId, optLoader.modelData.key) ?? false
                            onCheckedChanged: WidgetsStore.setOption(section.modelData.widgetId, optLoader.modelData.key, checked)
                        }
                    }
                    Component {
                        id: spinOption
                        ConfigSpinBox {
                            icon: optLoader.modelData.icon ?? ""
                            text: optLoader.modelData.label
                            value: WidgetCatalog.option(section.modelData.widgetId, optLoader.modelData.key) ?? 0
                            from: optLoader.modelData.min ?? 0
                            to: optLoader.modelData.max ?? 100
                            stepSize: optLoader.modelData.step ?? 1
                            onValueChanged: WidgetsStore.setOption(section.modelData.widgetId, optLoader.modelData.key, value)
                        }
                    }
                }
            }

            Loader {
                Layout.fillWidth: true
                active: section.modelData.settingsPage !== "" && WidgetCatalog.isEnabled(section.modelData.widgetId)
                source: active ? section.modelData.resolve(section.modelData.settingsPage) : ""
            }
        }
    }
}
