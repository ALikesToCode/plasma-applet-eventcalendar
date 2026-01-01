import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Item {
	id: root
	Layout.fillWidth: true
	implicitWidth: layout.implicitWidth
	implicitHeight: layout.implicitHeight

	property alias text: heading.text
	property alias level: heading.level
	property alias color: heading.color
	property bool showUnderline: heading.level <= 2

	ColumnLayout {
		id: layout
		width: parent ? parent.width : implicitWidth
		spacing: 0

		Kirigami.Heading {
			id: heading
			text: "Heading"
			level: 2
			color: Kirigami.Theme.textColor
			Layout.fillWidth: true
		}

		Rectangle {
			visible: root.showUnderline
			Layout.fillWidth: true
			height: 1
			color: heading.color
		}
	}
}
