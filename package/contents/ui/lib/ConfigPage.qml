// Version 4

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami

KCM.SimpleKCM {
	id: page
	Layout.fillWidth: true
	default property alias _contentChildren: content.data
	Layout.fillHeight: true

	ScrollView {
		id: scrollView
		anchors.fill: parent
		clip: true

		ColumnLayout {
			id: content
			width: scrollView.availableWidth
			spacing: Kirigami.Units.smallSpacing

			// Workaround for crash when using default on a Layout.
			// https://bugreports.qt.io/browse/QTBUG-52490
			// Still affecting Qt 5.7.0
			Component.onDestruction: {
				while (children.length > 0) {
					children[children.length - 1].parent = page
				}
			}
		}
	}

	property alias showAppletVersion: appletVersionLoader.active
	Loader {
		id: appletVersionLoader
		active: false
		visible: active
		source: "AppletVersion.qml"
		anchors.right: parent.right
		anchors.bottom: parent.top
	}
}
