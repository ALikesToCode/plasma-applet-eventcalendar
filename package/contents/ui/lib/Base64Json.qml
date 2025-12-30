import QtQuick

import "ConfigUtils.js" as ConfigUtils

QtObject {
	property string configKey
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

	onConfigValueChanged: deserialize()

	Component.onCompleted: configBridge = ConfigUtils.findBridge(this)

	function deserialize() {
		var s = JSON.parse(Qt.atob(configValue))
		value = s
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
