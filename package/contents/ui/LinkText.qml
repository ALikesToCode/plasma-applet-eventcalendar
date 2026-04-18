import QtQuick 2.0
import QtQuick.Controls 1.0
import org.kde.plasma.core 2.0 as PlasmaCore
import "Shared.js" as Shared

Label {
	function plainText() {
		return (text || "").replace(/<[^>]+>/g, " ").replace(/\s+/g, " ").trim()
	}

	Accessible.role: Accessible.StaticText
	Accessible.name: plainText()

	linkColor: PlasmaCore.ColorScope.highlightColor
	onLinkActivated: Shared.openExternalUrl(link)
	MouseArea {
		anchors.fill: parent
		acceptedButtons: Qt.NoButton // we don't want to eat clicks on the Text
		cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
	}
}
