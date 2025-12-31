import QtQuick

import "ConfigUtils.js" as ConfigUtils

QtObject {
	property string configKey
	property var configBridge: null
	readonly property var configValue: {
		if (!configKey) {
			return ""
		}
		if (configBridge) {
			var bridged = configBridge.read(configKey, undefined)
			return (bridged === undefined || bridged === null) ? "" : bridged
		}
		if (typeof plasmoid !== "undefined" && plasmoid.configuration) {
			var directValue = plasmoid.configuration[configKey]
			return (directValue === undefined || directValue === null) ? "" : directValue
		}
		return ""
	}
	property var value: null

	onConfigValueChanged: deserialize()

	Component.onCompleted: configBridge = ConfigUtils.findBridge(this)

	function deserialize() {
		if (configValue === "" || configValue === undefined || configValue === null) {
			value = []
			return
		}
		if (typeof configValue !== "string") {
			value = configValue || []
			return
		}
		var decoded = configValue
		try {
			decoded = Qt.atob(configValue)
		} catch (e) {
			decoded = configValue
		}
		try {
			value = JSON.parse(decoded)
		} catch (e2) {
			value = []
		}
	}

	function serialize() {
		var v = Qt.btoa(JSON.stringify(value))
		if (configBridge) {
			configBridge.write(configKey, v)
		} else if (typeof plasmoid !== "undefined" && plasmoid.configuration) {
			plasmoid.configuration[configKey] = v
			if (typeof kcm !== "undefined") {
				kcm.needsSave = true
			}
		}
	}
}
