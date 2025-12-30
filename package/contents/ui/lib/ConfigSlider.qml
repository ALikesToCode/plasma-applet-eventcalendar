// Version 2

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "ConfigUtils.js" as ConfigUtils

RowLayout {
	id: configSlider

	property string configKey: ''
	property var configBridge: null
	property alias maximumValue: slider.to
	property alias minimumValue: slider.from
	property alias stepSize: slider.stepSize
	property alias updateValueWhileDragging: slider.live
	property alias value: slider.value

	property alias before: labelBefore.text
	property alias after: labelAfter.text

	Layout.fillWidth: true

	Label {
		id: labelBefore
		text: ""
		visible: text
	}
	
	Slider {
		id: slider
		Layout.fillWidth: configSlider.Layout.fillWidth

		value: {
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
		// onValueChanged: plasmoid.configuration[configKey] = value
		onValueChanged: serializeTimer.start()
		to: 2147483647
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
			if (!configKey) {
				return
			}
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

	Component.onCompleted: configBridge = ConfigUtils.findBridge(configSlider)
}
