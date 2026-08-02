pragma Singleton
import Quickshell
import QtQuick

/**
 * One open click-to-toggle bar popup at a time, so two widgets (vpn, kdeconnect) don't
 * stack. A popup calls open(self) on show and closed(self) on hide; self needs a close().
 */
Singleton {
    id: root
    property var current: null

    function open(popup) {
        const previous = root.current
        root.current = popup
        if (previous && previous !== popup)
            previous.close()
    }

    function closed(popup) {
        if (root.current === popup)
            root.current = null
    }
}
