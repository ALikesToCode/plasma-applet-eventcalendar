import QtQuick

import "../lib/ConfigUtils.js" as ConfigUtils
import "../lib/SafeConfig.js" as SafeConfig

QtObject {
	id: obj
	property string configKey: ""
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
		try {
			var payload = SafeConfig.serializeBase64Json(value)
			if (configBridge) {
				configBridge.write(configKey, payload)
			} else if (typeof plasmoid !== "undefined" && plasmoid.configuration) {
				plasmoid.configuration[configKey] = payload
				if (typeof kcm !== "undefined") {
					kcm.needsSave = true
				}
			}
		} catch (err) {
			console.warn("[eventcalendar] Failed to serialize config", configKey, err)
		}
	}

	function deserialize() {
		try {
			value = SafeConfig.parseBase64Json(configValue, defaultValue)
		} catch (err) {
			console.warn("[eventcalendar] Failed to parse config", configKey, err)
			value = defaultValue
		}
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
