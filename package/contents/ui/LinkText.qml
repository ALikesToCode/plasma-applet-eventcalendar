import QtQuick
import QtQuick.Controls
import org.kde.kirigami as Kirigami

import "Shared.js" as Shared

Label {
	linkColor: Kirigami.Theme.highlightColor
	onLinkActivated: Shared.openExternalUrl(link)

	MouseArea {
		anchors.fill: parent
		acceptedButtons: Qt.NoButton // we don't want to eat clicks on the Text
		cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
	}
}
