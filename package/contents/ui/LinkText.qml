import QtQuick
import QtQuick.Controls
import org.kde.kirigami as Kirigami

import "Shared.js" as Shared

Label {
	function plainText() {
		return (text || "").replace(/<[^>]+>/g, " ").replace(/\s+/g, " ").trim()
	}

	Accessible.role: Accessible.StaticText
	Accessible.name: plainText()

	linkColor: Kirigami.Theme.highlightColor
	onLinkActivated: Shared.openExternalUrl(link)

	MouseArea {
		anchors.fill: parent
		acceptedButtons: Qt.NoButton // we don't want to eat clicks on the Text
		cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
	}
}
