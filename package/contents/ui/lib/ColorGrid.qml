import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

GroupBox {
	id: colorGrid
	Layout.fillWidth: true
	default property alias _contentChildren: content.data

	GridLayout {
		id: content
		anchors.left: parent.left
		anchors.right: parent.right
		columns: 2

		Component.onCompleted: {
			for (var i = 0; i < children.length; i++) {
				var child = children[i]
				if (typeof child.configKey !== "undefined") {
					child.horizontalAlignment = Text.AlignRight
				}
			}
		}

		// Workaround for crash when using default on a Layout.
		// https://bugreports.qt.io/browse/QTBUG-52490
		// Still affecting Qt 5.7.0
		Component.onDestruction: {
			while (children.length > 0) {
				children[children.length - 1].parent = colorGrid
			}
		}
	}
}
