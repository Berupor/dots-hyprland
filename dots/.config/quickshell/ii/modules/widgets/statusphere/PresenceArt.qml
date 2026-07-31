pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import Qt5Compat.GraphicalEffects

/** Rounded album art with a music note fallback. */
Rectangle {
    id: root
    required property string source

    radius: Appearance.rounding.small
    color: Appearance.colors.colLayer1

    StyledImage {
        id: image
        anchors.fill: parent
        source: root.source
        fillMode: Image.PreserveAspectCrop
        cache: true

        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: image.width
                height: image.height
                radius: root.radius
            }
        }
    }

    MaterialSymbol {
        visible: image.status !== Image.Ready
        anchors.centerIn: parent
        iconSize: Math.round(root.height * 0.4)
        color: Appearance.colors.colSubtext
        text: "music_note"
    }
}
