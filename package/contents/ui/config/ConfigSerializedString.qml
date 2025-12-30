import QtQuick

import "../lib/ConfigUtils.js" as ConfigUtils

QtObject {
	id: obj
	property string configKey: ''
	property var configBridge: null
	readonly property string configValue: {
		if (!configKey) {
			return ""
		}
		if (configBridge) {
			var bridged = configBridge.read(configKey, "")
			return (bridged === undefined || bridged === null) ? "" : String(bridged)
		}
		if (typeof plasmoid !== "undefined" && plasmoid.configuration) {
			var directValue = plasmoid.configuration[configKey]
			return (directValue === undefined || directValue === null) ? "" : String(directValue)
		}
		return ""
	}
	property var value: null
	property var defaultValue: ({}) // Empty Map

	Component.onCompleted: configBridge = ConfigUtils.findBridge(obj)

	function serialize() {
		var payload = Qt.btoa(JSON.stringify(value))
		if (configBridge) {
			configBridge.write(configKey, payload)
		} else if (typeof plasmoid !== "undefined" && plasmoid.configuration) {
			plasmoid.configuration[configKey] = payload
			if (typeof kcm !== "undefined") {
				kcm.needsSave = true
			}
		}
	}

	function deserialize() {
		value = configValue ? JSON.parse(Qt.atob(configValue)) : defaultValue
	}

	onConfigKeyChanged: deserialize()
	onConfigValueChanged: deserialize()
	onValueChanged: {
		if (value === null) {
			return // 99% of the time this is unintended
		}
		serialize()
	}
}
