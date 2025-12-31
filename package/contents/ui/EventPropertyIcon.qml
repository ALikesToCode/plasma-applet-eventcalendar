import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

ColumnLayout {
	id: eventDialogIcon
	Layout.fillHeight: true

	property alias source: iconItem.source
	property int size: Kirigami.Units.iconSizes.smallMedium

	Kirigami.Icon {
		id: iconItem
		Layout.alignment: Qt.AlignVCenter

		implicitWidth: eventDialogIcon.size
		implicitHeight: eventDialogIcon.size
	}
}
