import QtQuick 2.15
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.kirigami 2.20 as Kirigami

PlasmoidItem {
    id: eventBadgeCount

    Rectangle {
        anchors.right: eventBadgeCount.right
        anchors.bottom: eventBadgeCount.bottom

        height: eventBadgeCount.height / 3
        width: eventBadgeCountText.width
        color: {
            if (plasmoid.configuration.showOutlines) {
                var c = Qt.darker(Kirigami.Theme.backgroundColor, 1.0)
                c.a = 0.6
                return c
            } else {
                return "transparent"
            }
        }

        PlasmaComponents3.Label {
            id: eventBadgeCountText
            height: parent.height
            width: Math.max(paintedWidth, height)
            anchors.centerIn: parent

            color: Kirigami.Theme.highlightColor
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
