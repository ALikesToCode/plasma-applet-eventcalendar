import QtQuick 2.15
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.components 3.0 as PlasmaComponents3

PlasmoidItem {
    id: eventBadgeCount

    Rectangle {
        // Anchoring directly to eventBadgeCount avoids potential issues where "parent" may not be correctly resolved at runtime, particularly if the property evaluation context changes.
        anchors.right: eventBadgeCount.right
        anchors.bottom: eventBadgeCount.bottom

        height: eventBadgeCount.height / 3
        width: eventBadgeCountText.width
        color: {
            if (plasmoid.configuration.showOutlines) {
                var c = Qt.darker(PlasmaComponents3.Theme.backgroundColor, 1.0); // Adjusted for Plasma 6 compatibility
                c.a = 0.6; // Set alpha to 60%
                return c;
            } else {
                return "transparent";
            }
        }

        PlasmaComponents3.Label {
            id: eventBadgeCountText
            height: parent.height
            width: Math.max(paintedWidth, height)
            anchors.centerIn: parent

            color: PlasmaComponents3.Theme.highlightColor // Adjusted for Plasma 6 compatibility
            text: modelEventsCount
            font.weight: Font.Bold
            font.pointSize: 1024
            fontSizeMode: Text.VerticalFit
            wrapMode: Text.NoWrap

            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            smooth: true
        }
    }
}
