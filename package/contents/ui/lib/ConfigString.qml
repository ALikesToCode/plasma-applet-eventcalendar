// Version 2

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "ConfigUtils.js" as ConfigUtils

TextField {
	id: configString
	Layout.fillWidth: true

	property string configKey: ''
	property var configBridge: null
	property alias value: configString.text
	readonly property string configValue: {
		if (!configKey) {
			return ""
		}
		if (configBridge) {
			var bridged = configBridge.read(configKey, defaultValue)
			return (bridged === undefined || bridged === null) ? "" : String(bridged)
		}
		if (typeof plasmoid !== "undefined" && plasmoid.configuration) {
			var directValue = plasmoid.configuration[configKey]
			return (directValue === undefined || directValue === null) ? "" : String(directValue)
		}
		return ""
	}
	onConfigValueChanged: {
		if (!configString.focus && value != configValue) {
			value = configValue
		}
	}
	property string defaultValue: ""

	text: configString.configValue
	onTextChanged: serializeTimer.restart()

	Component.onCompleted: configBridge = ConfigUtils.findBridge(configString)

	ToolButton {
		icon.name: "edit-clear"
		onClicked: configString.value = defaultValue

		anchors.top: parent.top
		anchors.right: parent.right
		anchors.bottom: parent.bottom

		width: height
	}

	Timer { // throttle
		id: serializeTimer
		interval: 300
		onTriggered: {
			if (configKey) {
				if (configBridge) {
					configBridge.write(configKey, value)
				} else if (typeof plasmoid !== "undefined" && plasmoid.configuration) {
					plasmoid.configuration[configKey] = value
					if (typeof kcm !== "undefined") {
						kcm.needsSave = true
					}
				}
			}
		}
	}
}
