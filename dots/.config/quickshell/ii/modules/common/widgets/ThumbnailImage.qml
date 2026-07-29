import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

/**
 * Thumbnail image. It currently generates to the right place at the right size, but does not handle metadata/maintenance on modification.
 * See Freedesktop's spec: https://specifications.freedesktop.org/thumbnail-spec/thumbnail-spec-latest.html
 */
StyledImage {
    id: root

    property bool generateThumbnail: true
    required property string sourcePath
    property string thumbnailSizeName: Images.thumbnailSizeNameForDimensions(sourceSize.width, sourceSize.height)
    property string thumbnailPath: {
        if (sourcePath.length == 0) return "";
        const resolvedUrlWithoutFileProtocol = FileUtils.trimFileProtocol(`${Qt.resolvedUrl(sourcePath)}`);
        const encodedUrlWithoutFileProtocol = resolvedUrlWithoutFileProtocol.split("/").map(part => encodeURIComponent(part)).join("/");
        const md5Hash = Qt.md5(`file://${encodedUrlWithoutFileProtocol}`);
        return `${Directories.genericCache}/thumbnails/${thumbnailSizeName}/${md5Hash}.png`;
    }
    property int _generation: 0
    source: thumbnailPath.length > 0 ? `${thumbnailPath}#${_generation}` : ""

    asynchronous: true
    smooth: true
    mipmap: false

    opacity: status === Image.Ready ? 1 : 0
    Behavior on opacity {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }

    onThumbnailPathChanged: {
        root._retries = 0;
        root.regenerate();
    }

    property int _retries: 0
    readonly property int maxRetries: 5

    // Built here, not as a command binding: that binding may still hold the previous path when
    // this runs, which sends magick at the old destination and quietly generates nothing.
    function regenerate(): void {
        if (!root.generateThumbnail || root.thumbnailPath.length === 0) return;
        const maxSize = Images.thumbnailSizes[root.thumbnailSizeName];
        const dest = FileUtils.trimFileProtocol(root.thumbnailPath);
        thumbnailGeneration.running = false;
        thumbnailGeneration.command = ["bash", "-c",
            `[ -f '${dest}' ] && exit 0 || { mkdir -p "$(dirname '${dest}')" && magick '${root.sourcePath}' -resize ${maxSize}x${maxSize} '${dest}' && exit 1 || exit 2; }`
        ];
        thumbnailGeneration.running = true;
    }

    Process {
        id: thumbnailGeneration
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 1) { // Bust the cache without breaking the source binding
                root._generation += 1;
            } else if (exitCode === 2 && root._retries < root.maxRetries) { // Source may not be on disk yet
                root._retries += 1;
                retryTimer.restart();
            }
        }
    }
    Timer {
        id: retryTimer
        interval: 1000 * root._retries
        onTriggered: root.regenerate()
    }
}
