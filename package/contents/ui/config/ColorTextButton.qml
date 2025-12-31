import QtQuick
import QtQuick.Controls
import org.kde.kirigami as Kirigami

Button {
	id: colorTextButton
	padding: Kirigami.Units.smallSpacing
	implicitWidth: padding + colorTextLabel.implicitWidth + padding
	implicitHeight: padding + colorTextLabel.implicitHeight + padding

	property alias label: colorTextLabel.text

	Label {
		id: colorTextLabel
		anchors.centerIn: parent
		color: Kirigami.Theme.buttonTextColor === undefined
			? Kirigami.Theme.textColor
			: Kirigami.Theme.buttonTextColor
	}
}
