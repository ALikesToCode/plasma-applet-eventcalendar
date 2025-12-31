// Version 3

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "ConfigUtils.js" as ConfigUtils

RowLayout {
	id: configSpinBox

	property string configKey: ''
	property var configBridge: null
	readonly property real configValue: {
		if (!configKey) {
			return 0
		}
		if (configBridge) {
			return Number(configBridge.read(configKey, 0))
		}
		if (typeof plasmoid !== "undefined" && plasmoid.configuration) {
			return Number(plasmoid.configuration[configKey])
		}
		return 0
	}
	property int decimals: 0
	property int horizontalAlignment: Text.AlignLeft
	property real maximumValue: 2147483647
	property real minimumValue: 0
	property string prefix: ""
	property real stepSize: 1
	property string suffix: ""
	property real value: 0

	property alias before: labelBefore.text
	property alias after: labelAfter.text

	Label {
		id: labelBefore
		text: ""
		visible: text
	}
	
	SpinBox {
		id: spinBox

		from: configSpinBox._toScaled(configSpinBox.minimumValue)
		to: configSpinBox._toScaled(configSpinBox.maximumValue)
		stepSize: configSpinBox._toScaled(configSpinBox.stepSize)
		value: configSpinBox._toScaled(configSpinBox.value)
		editable: true

		textFromValue: function(v, locale) {
			var numberValue = configSpinBox._fromScaled(v)
			var text = configSpinBox._decimals > 0
				? numberValue.toFixed(configSpinBox._decimals)
				: Math.round(numberValue).toString()
			return configSpinBox.prefix + text + configSpinBox.suffix
		}

		valueFromText: function(text, locale) {
			var stripped = text
			if (configSpinBox.prefix) {
				stripped = stripped.replace(configSpinBox.prefix, "")
			}
			if (configSpinBox.suffix) {
				stripped = stripped.replace(configSpinBox.suffix, "")
			}
			var parsed = parseFloat(stripped)
			if (isNaN(parsed)) {
				parsed = 0
			}
			return configSpinBox._toScaled(parsed)
		}

		onValueModified: serializeTimer.start()
		Component.onCompleted: configSpinBox._applyAlignment()
	}

	Label {
		id: labelAfter
		text: ""
		visible: text
	}

	Timer { // throttle
		id: serializeTimer
		interval: 300
		onTriggered: {
			var newValue = configSpinBox._fromScaled(spinBox.value)
			if (configKey) {
				if (configBridge) {
					configBridge.write(configKey, newValue)
				} else if (typeof plasmoid !== "undefined" && plasmoid.configuration) {
					plasmoid.configuration[configKey] = newValue
					if (typeof kcm !== "undefined") {
						kcm.needsSave = true
					}
				}
			}
			configSpinBox.value = newValue
		}
	}

	readonly property int _decimals: {
		if (decimals > 0) {
			return decimals
		}
		return Math.max(_fractionDigits(minimumValue), _fractionDigits(maximumValue), _fractionDigits(stepSize))
	}

	readonly property real _scale: Math.pow(10, _decimals)

	function _fractionDigits(numberValue) {
		var text = String(numberValue)
		var dotIndex = text.indexOf(".")
		return dotIndex >= 0 ? (text.length - dotIndex - 1) : 0
	}

	function _toScaled(numberValue) {
		return Math.round(numberValue * _scale)
	}

	function _fromScaled(numberValue) {
		return numberValue / _scale
	}

	function _applyAlignment() {
		if (spinBox.contentItem && typeof spinBox.contentItem.horizontalAlignment !== "undefined") {
			spinBox.contentItem.horizontalAlignment = horizontalAlignment
		}
	}

	onHorizontalAlignmentChanged: _applyAlignment()

	onConfigValueChanged: {
		if (configKey) {
			value = configValue
		}
	}

	onValueChanged: {
		var scaled = _toScaled(value)
		if (spinBox.value !== scaled) {
			spinBox.value = scaled
		}
	}

	Component.onCompleted: {
		configBridge = ConfigUtils.findBridge(configSpinBox)
		if (configKey) {
			value = configValue
		}
	}
}
