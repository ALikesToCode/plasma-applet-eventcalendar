// Version 4

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

/*
** Example:
**
ConfigRadioButtonGroup {
	configKey: "appDescription"
	model: [
		{ value: "a", text: i18n("A") },
		{ value: "b", text: i18n("B") },
		{ value: "c", text: i18n("C") },
	]
}
*/

RowLayout {
	id: configRadioButtonGroup
	Layout.fillWidth: true
	default property alias _contentChildren: content.data
	property alias label: label.text

	property ButtonGroup buttonGroup: ButtonGroup { id: radioButtonGroup }
	property alias exclusiveGroup: radioButtonGroup

	property string configKey: ''
	readonly property var configValue: configKey ? plasmoid.configuration[configKey] : ""

	property alias model: buttonRepeater.model

	//---
	Label {
		id: label
		visible: !!text
		Layout.alignment: Qt.AlignTop | Qt.AlignLeft
	}
	ColumnLayout {
		id: content

		Repeater {
			id: buttonRepeater
			RadioButton {
				visible: typeof modelData.visible !== "undefined" ? modelData.visible : true
				enabled: typeof modelData.enabled !== "undefined" ? modelData.enabled : true
				text: modelData.text
				checked: modelData.value === configValue
				ButtonGroup.group: radioButtonGroup
				onClicked: {
					focus = true
					if (configKey) {
						plasmoid.configuration[configKey] = modelData.value
					}
				}
			}
		}
	}
}
