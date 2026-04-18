import QtQuick 2.0
import "../lib/SafeConfig.js" as SafeConfig

QtObject {
	id: obj
	property string configKey: ''
	readonly property string configValue: configKey ? plasmoid.configuration[configKey] : ''
	property var value: null
	property var defaultValue: ({}) // Empty Map

	function serialize() {
		try {
			plasmoid.configuration[configKey] = SafeConfig.serializeBase64Json(value)
		} catch (err) {
			console.warn('[eventcalendar] Failed to serialize config', configKey, err)
		}
	}

	function deserialize() {
		try {
			value = SafeConfig.parseBase64Json(configValue, defaultValue)
		} catch (err) {
			console.warn('[eventcalendar] Failed to parse config', configKey, err)
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
