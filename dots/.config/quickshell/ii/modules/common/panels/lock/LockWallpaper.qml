import qs.modules.common
import qs.modules.common.functions
import QtQuick
import Qt5Compat.GraphicalEffects

/** Wallpaper for the lock surface, blurred like the one on the background layer. */
Item {
    id: root

    Image {
        id: wallpaper
        anchors.fill: parent
        source: Config.options.background.wallpaperPath ? "file://" + Config.options.background.wallpaperPath : ""
        fillMode: Image.PreserveAspectCrop
        cache: true
        asynchronous: false
        visible: status === Image.Ready
    }

    Loader {
        active: Config.options.lock.blur.enable && wallpaper.status === Image.Ready
        anchors.fill: wallpaper
        scale: Config.options.lock.blur.extraZoom // Also hides the blur bleeding at the edges
        sourceComponent: GaussianBlur {
            source: wallpaper
            radius: Config.options.lock.blur.radius
            samples: radius * 2 + 1

            Rectangle {
                anchors.fill: parent
                color: ColorUtils.transparentize(Appearance.colors.colLayer0, 0.7)
            }
        }
    }
}
