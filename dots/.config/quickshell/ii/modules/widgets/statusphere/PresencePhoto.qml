pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.widgets
import QtQuick
import Qt5Compat.GraphicalEffects

/** A friend's current shared photo, with a relative-time corner label. No captions, no reactions. */
Rectangle {
    id: root
    property var photo: null // { account_id, path, created_at, expires_at }

    readonly property int minHeight: Statusphere.opt("photoMinHeight")
    readonly property int maxHeight: Statusphere.opt("photoMaxHeight")
    // Shared regions come in every shape, so the card follows the image instead of cropping it to a fixed strip
    readonly property real naturalHeight: image.implicitHeight > 0 ? root.width * image.implicitHeight / image.implicitWidth : 0

    implicitHeight: root.naturalHeight > 0 ? Math.round(Math.max(root.minHeight, Math.min(root.maxHeight, root.naturalHeight))) : root.minHeight
    radius: Appearance.rounding.normal
    color: Appearance.colors.colLayer1

    Behavior on implicitHeight {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }

    ThumbnailImage {
        id: image
        anchors.fill: parent
        sourcePath: root.photo?.path ?? ""
        thumbnailSizeName: "x-large" // The default sizes itself off sourceSize, which is 0 before the first load
        // Panoramas get letterboxed rather than gutted; anything taller is cropped to maxHeight
        fillMode: root.naturalHeight > 0 && root.naturalHeight < root.minHeight ? Image.PreserveAspectFit : Image.PreserveAspectCrop

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
        iconSize: Math.round(root.height * 0.3)
        color: Appearance.colors.colSubtext
        text: "photo_camera"
    }

    Rectangle {
        visible: root.photo !== null
        anchors {
            right: parent.right
            bottom: parent.bottom
            margins: 8
        }
        radius: Appearance.rounding.full
        color: Appearance.colors.colScrim
        implicitWidth: timeLabel.implicitWidth + 12
        implicitHeight: timeLabel.implicitHeight + 6

        StyledText {
            id: timeLabel
            anchors.centerIn: parent
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: "white"
            text: root.photo ? NotificationUtils.getFriendlyNotifTimeString(Date.parse(root.photo.created_at)) : ""
        }
    }
}
