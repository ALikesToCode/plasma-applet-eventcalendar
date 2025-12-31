import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3

Item {
	id: eventBadgeCount

	Rectangle {
		// This spams "TypeError: Cannot read property of null" when month is changed...
		// anchors.right: parent.right
		// anchors.bottom: parent.bottom

		// This doesn't ... why?!
		anchors.right: eventBadgeCount.right
		anchors.bottom: eventBadgeCount.bottom

		height: parent.height / 3
		width: eventBadgeCountText.width
		color: {
			if (plasmoid.configuration.showOutlines) {
				var c = Qt.darker(Kirigami.Theme.backgroundColor, 1) // Cast to color
				c.a = 0.6 // 60%
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

