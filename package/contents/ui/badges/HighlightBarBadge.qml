import QtQuick 2.15
import org.kde.plasma.plasmoid 2.0
import org.kde.kirigami 2.20 as Kirigami

PlasmoidItem {
    id: highlightBarBadge

    Rectangle {
        anchors.left: highlightBarBadge.left
        anchors.right: highlightBarBadge.right
        anchors.bottom: parent.bottom
        height: parent.height / 8
        opacity: 0.6
        color: Kirigami.Theme.highlightColor
    }
}
