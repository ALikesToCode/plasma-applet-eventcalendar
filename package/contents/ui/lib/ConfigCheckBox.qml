// Version 2

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "ConfigUtils.js" as ConfigUtils

import ".."

CheckBox {
	id: configCheckBox

	property string configKey: ''
	property var configBridge: null

	readonly property bool configValue: {
		if (!configKey) {
			return false
		}
		if (configBridge) {
			return !!configBridge.read(configKey, false)
		}
		if (typeof plasmoid !== "undefined" && plasmoid.configuration) {
			return !!plasmoid.configuration[configKey]
		}
		return false
	}

	checked: configValue

	Component.onCompleted: configBridge = ConfigUtils.findBridge(configCheckBox)

	onClicked: {
		if (!configKey) {
			return
		}
		if (configBridge) {
			configBridge.write(configKey, checked)
		} else if (typeof plasmoid !== "undefined" && plasmoid.configuration) {
			plasmoid.configuration[configKey] = checked
			if (typeof kcm !== "undefined") {
				kcm.needsSave = true
			}
		}
	}
}
