import QtQuick 2.0
import "SafeConfig.js" as SafeConfig

QtObject {
	property string configKey
	readonly property string configValue: plasmoid.configuration[configKey]
	property var defaultValue: null
	property var value: null

	onConfigValueChanged: deserialize()

	function deserialize() {
		try {
			value = SafeConfig.parseBase64Json(configValue, defaultValue)
		} catch (err) {
			console.warn('[eventcalendar] Failed to parse base64 config', configKey, err)
			value = defaultValue
		}
	}

	function serialize() {
		try {
			plasmoid.configuration[configKey] = SafeConfig.serializeBase64Json(value)
		} catch (err) {
			console.warn('[eventcalendar] Failed to serialize base64 config', configKey, err)
		}
	}
}
