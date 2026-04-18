import QtQuick

import "ConfigUtils.js" as ConfigUtils
import "SafeConfig.js" as SafeConfig

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
	property var defaultValue: []
	property var value: null

	onConfigValueChanged: deserialize()

	Component.onCompleted: configBridge = ConfigUtils.findBridge(this)

	function deserialize() {
		if (configValue === "" || configValue === undefined || configValue === null) {
			value = defaultValue
			return
		}
		if (typeof configValue !== "string") {
			value = configValue || defaultValue
			return
		}
		try {
			value = SafeConfig.parseBase64Json(configValue, defaultValue)
		} catch (err) {
			console.warn("[eventcalendar] Failed to parse base64 config", configKey, err)
			value = defaultValue
		}
	}

	function serialize() {
		try {
			var serializedValue = SafeConfig.serializeBase64Json(value)
			if (configBridge) {
				configBridge.write(configKey, serializedValue)
			} else if (typeof plasmoid !== "undefined" && plasmoid.configuration) {
				plasmoid.configuration[configKey] = serializedValue
				if (typeof kcm !== "undefined") {
					kcm.needsSave = true
				}
			}
		} catch (err) {
			console.warn("[eventcalendar] Failed to serialize base64 config", configKey, err)
		}
	}
}
