import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

GroupBox {
	id: configSection
	Layout.fillWidth: true
	default property alias _contentChildren: content.data

	ColumnLayout {
		id: content
		anchors.left: parent.left
		anchors.right: parent.right

		// Workaround for crash when using default on a Layout.
		// https://bugreports.qt.io/browse/QTBUG-52490
		// Still affecting Qt 5.7.0
		Component.onDestruction: {
			while (children.length > 0) {
				children[children.length - 1].parent = configSection
			}
		}
	}
}
