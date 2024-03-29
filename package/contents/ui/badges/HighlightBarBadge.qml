import QtQuick 2.15
import org.kde.plasma.plasmoid 2.0

PlasmoidItem {
    id: highlightBarBadge

    Rectangle {
        anchors.left: highlightBarBadge.left
        anchors.right: highlightBarBadge.right
        anchors.bottom: parent.bottom
        height: parent.height / 8
        opacity: 0.6
        color: Plasmoid.theme.highlightColor // Adjusted for Plasma 6
    }
}
