import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Item {
	id: eventColorsBarColor

	Item {
		anchors.left: eventColorsBarColor.left
		anchors.right: eventColorsBarColor.right
		anchors.bottom: eventColorsBarColor.bottom
		height: parent.height / 8
		
		property bool usePadding: !plasmoid.configuration.monthShowBorder
		anchors.leftMargin: usePadding ? parent.width/8 : 0
		anchors.rightMargin: usePadding ? parent.width/8 : 0
		anchors.bottomMargin: usePadding ? parent.height/16 : 0

		RowLayout {
			anchors.fill: parent
			spacing: 0

			Repeater {
				model: dayStyle.useHightlightColor ? [Kirigami.Theme.highlightColor] : dayStyle.eventColors

				Rectangle {
					Layout.fillHeight: true
					Layout.fillWidth: true
					color: modelData

					Rectangle {
						anchors.fill: parent
						color: "transparent"
						border.width: 1
						border.color: Kirigami.Theme.backgroundColor
						opacity: 0.5
					}
				}
				
			}
		}
	}
}

