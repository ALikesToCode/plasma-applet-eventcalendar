import QtQuick 2.15
import org.kde.kirigami 2.20 as Kirigami
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.1 as PlasmaCore

Item {
	id: dotsBadge
	property int dotSize: (height / 8) + dotBorderWidth*2
	property color dotColor: Kirigami.Theme.highlightColor
	property int dotBorderWidth: plasmoid.configuration.showOutlines ? 1 : 0
	property color dotBorderColor: Kirigami.Theme.backgroundColor
	property int modelEventsCount: 0

	Row {
		anchors.horizontalCenter: dotsBadge.horizontalCenter
		anchors.bottom: dotsBadge.bottom
		anchors.margins: dotsBadge.height / 8
		spacing: PlasmaCore.Units.smallSpacing

		Rectangle {
			visible: modelEventsCount >= 1
			width: dotsBadge.dotSize
			height: dotsBadge.dotSize
			radius: width / 2
			color: dotsBadge.dotColor
			border.width: dotsBadge.dotBorderWidth
			border.color: dotsBadge.dotBorderColor
		}
		Rectangle {
			visible: modelEventsCount >= 2
			width: dotsBadge.dotSize
			height: dotsBadge.dotSize
			radius: width / 2
			color: dotsBadge.dotColor
			border.width: dotsBadge.dotBorderWidth
			border.color: dotsBadge.dotBorderColor
		}
		Rectangle {
			visible: modelEventsCount >= 3
			width: dotsBadge.dotSize
			height: dotsBadge.dotSize
			radius: width / 2
			color: dotsBadge.dotColor
			border.width: dotsBadge.dotBorderWidth
			border.color: dotsBadge.dotBorderColor
		}
	}
}
