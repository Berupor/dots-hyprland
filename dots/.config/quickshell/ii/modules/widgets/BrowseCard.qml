import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.widgets

/**
 * Widgets from the registry, installed by a button instead of a pasted url.
 * Fetches when opened, so a closed card touches the network never.
 */
CatalogCard {
    id: root
    readonly property bool failed: WidgetRegistry.state === WidgetRegistry.State.Failed
    readonly property bool ready: WidgetRegistry.state === WidgetRegistry.State.Ready

    /// Why the list looks the way it does
    readonly property string statusText: {
        if (WidgetRegistry.busy)
            return Translation.tr("Loading the list");
        if (root.failed)
            return WidgetRegistry.message;
        if (!root.ready)
            return Translation.tr("Widgets to install by name");
        const parts = [Translation.tr("%1 to install").arg(WidgetRegistry.listed.length)];
        if (WidgetRegistry.unsupported > 0)
            parts.push(Translation.tr("%1 need another shell version").arg(WidgetRegistry.unsupported));
        if (WidgetRegistry.stale)
            parts.push(Translation.tr("offline, from the cached list"));
        return parts.join(" · ");
    }

    icon: "travel_explore"
    title: Translation.tr("Browse widgets")
    subtitle: root.statusText
    subtitleColor: root.failed ? Appearance.colors.colError : Appearance.colors.colSubtext
    iconColor: Appearance.colors.colTertiaryContainer
    iconSymbolColor: Appearance.colors.colOnTertiaryContainer

    onExpandedChanged: if (expanded) WidgetRegistry.load(false)

    /// Whose install this card started: the installer also talks about widgets
    /// removed or updated elsewhere, and those are not this list's business
    property string ownJob: ""

    component EntryRow: Rectangle {
        id: entryRow
        required property var entry
        readonly property bool mine: root.ownJob === entry.id && WidgetInstaller.job === entry.id
        readonly property bool working: entryRow.mine && WidgetInstaller.busy
        readonly property string jobMessage: entryRow.mine ? WidgetInstaller.message : ""
        readonly property string metaText: [entry.author, entry.tags.join(", "), entry.dependencies.length > 0 ? Translation.tr("needs %1").arg(entry.dependencies.join(", ")) : ""].filter(s => s !== "").join(" · ")

        Layout.fillWidth: true
        Layout.bottomMargin: 6
        implicitHeight: entryLayout.implicitHeight + 12 * 2
        radius: Appearance.rounding.small
        color: Appearance.colors.colLayer2

        HoverHandler {
            id: rowHover
        }

        RowLayout {
            id: entryLayout
            anchors {
                left: parent.left
                right: parent.right
                verticalCenter: parent.verticalCenter
                leftMargin: 12
                rightMargin: 12
            }
            spacing: 12

            MaterialShapeWrappedMaterialSymbol {
                Layout.alignment: Qt.AlignVCenter
                text: entryRow.entry.icon
                iconSize: Appearance.font.pixelSize.large
                padding: 8
                color: Appearance.colors.colSurfaceContainerHighest
                colSymbol: Appearance.colors.colOnSurfaceVariant
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                StyledText {
                    Layout.fillWidth: true
                    text: entryRow.entry.name
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnLayer2
                    elide: Text.ElideRight
                }

                StyledText {
                    Layout.fillWidth: true
                    visible: text !== ""
                    // The installer takes the line over once it has something to say here
                    text: entryRow.jobMessage !== "" ? entryRow.jobMessage : entryRow.entry.description
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: WidgetInstaller.state === WidgetInstaller.State.Failed && entryRow.jobMessage !== "" ? Appearance.colors.colError : Appearance.colors.colSubtext
                    wrapMode: Text.WordWrap
                }

                StyledText {
                    Layout.fillWidth: true
                    Layout.topMargin: 2
                    visible: text !== ""
                    text: entryRow.metaText
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    color: Appearance.colors.colOutline
                    elide: Text.ElideRight
                }
            }

            Item { // A widget runs with the shell, so read it before installing it
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: 28
                implicitHeight: 28
                opacity: rowHover.hovered ? 1 : 0 // Install is the button here, this one waits to be looked for

                Behavior on opacity {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }

                MaterialSymbol {
                    anchors.centerIn: parent
                    text: "open_in_new"
                    iconSize: Appearance.font.pixelSize.large
                    color: openHover.hovered ? Appearance.colors.colOnLayer2 : Appearance.colors.colOnSurfaceVariant
                }

                HoverHandler {
                    id: openHover
                    enabled: rowHover.hovered
                    cursorShape: Qt.PointingHandCursor
                }

                TapHandler {
                    enabled: rowHover.hovered
                    onTapped: Quickshell.execDetached(["xdg-open", entryRow.entry.url])
                }

                StyledToolTip {
                    extraVisibleCondition: false
                    alternativeVisibleCondition: openHover.hovered
                    text: Translation.tr("Open %1").arg(entryRow.entry.url)
                }
            }

            RippleButtonWithIcon {
                Layout.alignment: Qt.AlignVCenter
                buttonRadius: Appearance.rounding.small
                colBackground: Appearance.colors.colSurfaceContainerHighest
                enabled: !WidgetInstaller.busy
                materialIcon: entryRow.working ? "hourglass_top" : "download"
                mainText: entryRow.working ? Translation.tr("Installing...") : Translation.tr("Install")
                onClicked: {
                    root.ownJob = entryRow.entry.id;
                    WidgetInstaller.install(entryRow.entry.url, entryRow.entry.id);
                }

                StyledToolTip {
                    text: Translation.tr("Clones into %1").arg(WidgetCatalog.externalDir)
                }
            }
        }
    }

    Repeater {
        model: root.bodyShown ? WidgetRegistry.listed : []
        delegate: EntryRow {
            required property var modelData
            entry: modelData
        }
    }

    StyledText { // Nothing to offer, and the two reasons for it read differently
        Layout.fillWidth: true
        Layout.topMargin: 4
        Layout.bottomMargin: 4
        visible: root.ready && WidgetRegistry.listed.length === 0
        text: WidgetRegistry.entries.length === 0 ? Translation.tr("The registry lists nothing yet.") : Translation.tr("Everything the registry lists is already installed.")
        font.pixelSize: Appearance.font.pixelSize.smaller
        color: Appearance.colors.colSubtext
        wrapMode: Text.WordWrap
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: 6
        spacing: 8

        StyledText {
            Layout.fillWidth: true
            text: Translation.tr("Add yours to %1").arg(`[${WidgetRegistry.homepage.replace("https://", "")}](${WidgetRegistry.homepage})`)
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Appearance.colors.colSubtext
            textFormat: Text.MarkdownText
            elide: Text.ElideRight
            onLinkActivated: link => Quickshell.execDetached(["xdg-open", link])

            PointingHandLinkHover {}
        }

        RippleButtonWithIcon {
            Layout.alignment: Qt.AlignVCenter
            buttonRadius: Appearance.rounding.small
            enabled: !WidgetRegistry.busy
            materialIcon: "refresh"
            mainText: Translation.tr("Refresh")
            onClicked: WidgetRegistry.load(true)

            StyledToolTip {
                text: Translation.tr("Fetches the list again instead of waiting for the cache to age")
            }
        }
    }
}
