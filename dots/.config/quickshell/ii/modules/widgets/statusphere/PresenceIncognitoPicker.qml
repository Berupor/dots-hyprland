pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.widgets
import qs.modules.common.widgets
import qs.services
import QtQuick

/** Takes over your own row while you hold it: slide onto a choice, let go. */
Item {
    id: root

    property bool open: false
    property int hovered: -1

    readonly property int chipSize: 34
    readonly property int chipSpacing: 6

    // Durations wear their own number: clock glyphs all look alike at chip size.
    readonly property var choices: [
        {
            "icon": "visibility",
            "chip": "",
            "label": Translation.tr("Visible"),
            "hide": false,
            "minutes": 0
        },
        {
            "icon": "",
            "chip": "15m",
            "label": Translation.tr("15 minutes"),
            "hide": true,
            "minutes": 15
        },
        {
            "icon": "",
            "chip": "1h",
            "label": Translation.tr("1 hour"),
            "hide": true,
            "minutes": 60
        },
        {
            "icon": "visibility_off",
            "chip": "",
            "label": Translation.tr("Until I say"),
            "hide": true,
            "minutes": 0
        }
    ]

    implicitHeight: root.chipSize
    opacity: root.open ? 1 : 0
    visible: opacity > 0

    Behavior on opacity {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }

    // Hit by column rather than by child item, so the gaps between chips don't drop the
    // selection mid-slide. Leaving the strip vertically means "never mind".
    function hoverAt(x: real, y: real): void {
        if (!root.open)
            return;
        const index = Math.floor(x / (root.chipSize + root.chipSpacing));
        const inside = y > -24 && y < root.height + 24 && index >= 0 && index < root.choices.length;
        root.hovered = inside ? index : -1;
    }

    function apply(): void {
        if (root.hovered < 0)
            return;
        const choice = root.choices[root.hovered];
        Statusphere.setIncognito(choice.hide, choice.minutes);
    }

    Row {
        id: chips
        anchors.verticalCenter: parent.verticalCenter
        spacing: root.chipSpacing

        Repeater {
            model: root.choices

            // The cell keeps its size and only the disc under the glyph grows: scaling the
            // whole chip resamples the glyph and turns it to mush.
            delegate: Item {
                id: chip
                required property var modelData
                required property int index

                readonly property bool active: root.hovered === chip.index
                readonly property real disc: root.open ? (chip.active ? root.chipSize : root.chipSize - 5) : 0

                width: root.chipSize
                height: root.chipSize
                opacity: root.open ? 1 : 0

                Behavior on opacity {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: chip.disc
                    height: chip.disc
                    radius: Appearance.rounding.full
                    color: chip.active ? Appearance.colors.colSecondaryContainer : Appearance.colors.colLayer2

                    Behavior on color {
                        animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                    }

                    Behavior on width { // Staggered, so the row fans out instead of blinking in
                        SequentialAnimation {
                            PauseAnimation {
                                duration: chip.index * 35
                            }
                            NumberAnimation {
                                duration: 240
                                easing.type: Easing.OutBack
                                easing.overshoot: 2.6
                            }
                        }
                    }

                    Behavior on height {
                        SequentialAnimation {
                            PauseAnimation {
                                duration: chip.index * 35
                            }
                            NumberAnimation {
                                duration: 240
                                easing.type: Easing.OutBack
                                easing.overshoot: 2.6
                            }
                        }
                    }
                }

                MaterialSymbol {
                    anchors.centerIn: parent
                    visible: chip.modelData.icon.length > 0
                    fill: 0 // Filled symbols turn to mush at chip size
                    text: chip.modelData.icon
                    iconSize: Appearance.font.pixelSize.large
                    color: chip.active ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer2
                }

                StyledText {
                    anchors.centerIn: parent
                    visible: chip.modelData.chip.length > 0
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    font.weight: 500
                    color: chip.active ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer2
                    text: chip.modelData.chip
                }
            }
        }
    }

    StyledText {
        anchors {
            left: chips.right
            leftMargin: 10
            right: parent.right
            verticalCenter: parent.verticalCenter
        }
        elide: Text.ElideRight
        font.pixelSize: Appearance.font.pixelSize.smaller
        color: root.hovered >= 0 ? Appearance.colors.colOnLayer2 : Appearance.colors.colSubtext
        text: root.hovered >= 0 ? root.choices[root.hovered].label : Translation.tr("Slide, then let go")
    }
}
