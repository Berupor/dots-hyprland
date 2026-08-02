//@ probe -g 100x40
/**
 * WidgetPopupCoordinator: opening a popup closes whatever was open before it.
 */
import qs.modules.widgets
import QtQuick

Item {
    id: probe
    property int aClosed: 0
    property int bClosed: 0

    QtObject {
        id: popupA
        function close() { probe.aClosed++; WidgetPopupCoordinator.closed(popupA); }
    }
    QtObject {
        id: popupB
        function close() { probe.bClosed++; WidgetPopupCoordinator.closed(popupB); }
    }

    function checks() {
        WidgetPopupCoordinator.open(popupA);
        const opensA = WidgetPopupCoordinator.current === popupA;

        WidgetPopupCoordinator.open(popupB);
        const openingBClosesA = probe.aClosed === 1 && WidgetPopupCoordinator.current === popupB;

        WidgetPopupCoordinator.closed(popupA); // stale close, A already dismissed by B
        const staleCloseIgnored = WidgetPopupCoordinator.current === popupB;

        popupB.close();
        const selfCloseClears = WidgetPopupCoordinator.current === null;

        WidgetPopupCoordinator.open(popupA);
        WidgetPopupCoordinator.open(popupA);
        const reopenSelfNoop = probe.aClosed === 1;

        return [
            { "name": "opening a popup makes it current", "got": opensA, "want": true },
            { "name": "opening a second popup closes the first", "got": openingBClosesA, "want": true },
            { "name": "a stale close from a non-current popup is ignored", "got": staleCloseIgnored, "want": true },
            { "name": "the current popup closing itself clears current", "got": selfCloseClears, "want": true },
            { "name": "opening the same popup again does not re-close it", "got": reopenSelfNoop, "want": true }
        ];
    }
}
