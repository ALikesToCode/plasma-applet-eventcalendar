import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

import ".."
import "../lib"

ConfigPage {
	id: page

	property int timezoneColumnWidth: Kirigami.Units.gridUnit * 12

	ListModel { id: timezoneListModel }

	function normalizedTimezones(list) {
		var zones = []
		if (Array.isArray(list)) {
			zones = list.slice(0)
		} else if (typeof list === "string") {
			zones = list.split(',')
		}
		var normalized = []
		for (var i = 0; i < zones.length; i++) {
			var zone = (zones[i] || "").trim()
			if (!zone) {
				continue
			}
			if (normalized.indexOf(zone) === -1) {
				normalized.push(zone)
			}
		}
		if (normalized.indexOf("Local") === -1) {
			normalized.unshift("Local")
		} else {
			normalized.splice(normalized.indexOf("Local"), 1)
			normalized.unshift("Local")
		}
		return normalized
	}

	function syncFromConfig() {
		var zones = normalizedTimezones(page.configBridge.read("selectedTimeZones", []))
		timezoneListModel.clear()
		for (var i = 0; i < zones.length; i++) {
			timezoneListModel.append({ zoneId: zones[i] })
		}
	}

	function updateConfig(zones) {
		page.configBridge.write("selectedTimeZones", normalizedTimezones(zones))
	}

	function addTimezone(zoneId) {
		var zone = (zoneId || "").trim()
		if (!zone) {
			return
		}
		var zones = normalizedTimezones(page.configBridge.read("selectedTimeZones", []))
		if (zones.indexOf(zone) === -1) {
			zones.push(zone)
			updateConfig(zones)
			syncFromConfig()
		}
		timezoneInput.text = ""
	}

	function removeTimezone(zoneId) {
		var zones = normalizedTimezones(page.configBridge.read("selectedTimeZones", []))
		var index = zones.indexOf(zoneId)
		if (index >= 0 && zoneId !== "Local") {
			zones.splice(index, 1)
			updateConfig(zones)
			syncFromConfig()
		}
	}

	function prettyZoneName(zoneId) {
		if (zoneId === "Local") {
			return i18n("Local")
		}
		var parts = zoneId.split('/')
		return parts[parts.length - 1].replace(/_/g, ' ')
	}

	Component.onCompleted: syncFromConfig()
	Connections {
		target: page
		function onCfg_selectedTimeZonesChanged() {
			syncFromConfig()
		}
	}

	ColumnLayout {
		Layout.fillWidth: true
		Layout.fillHeight: true
		spacing: Kirigami.Units.smallSpacing

		Label {
			Layout.fillWidth: true
			text: i18n("Enter time zone IDs (for example: Europe/London, America/New_York). The list controls which zones appear in the tooltip.")
			wrapMode: Text.Wrap
		}

		RowLayout {
			Layout.fillWidth: true
			TextField {
				id: timezoneInput
				Layout.fillWidth: true
				placeholderText: i18n("Time zone ID")
				onAccepted: addTimezone(text)
			}
			Button {
				text: i18n("Add")
				enabled: timezoneInput.text.trim().length > 0
				onClicked: addTimezone(timezoneInput.text)
			}
		}

		RowLayout {
			Layout.fillWidth: true
			Label {
				text: i18n("Time zones")
				font.bold: true
				Layout.preferredWidth: page.timezoneColumnWidth
			}
			Label {
				text: i18n("Identifier")
				font.bold: true
				Layout.fillWidth: true
			}
			Item { Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium }
		}

		ListView {
			id: timeZoneView
			Layout.fillWidth: true
			Layout.fillHeight: true
			clip: true
			model: timezoneListModel
			delegate: RowLayout {
				width: timeZoneView.width
				spacing: Kirigami.Units.smallSpacing

				Label {
					text: prettyZoneName(model.zoneId)
					Layout.preferredWidth: page.timezoneColumnWidth
					elide: Text.ElideRight
				}
				Label {
					text: model.zoneId
					Layout.fillWidth: true
					elide: Text.ElideRight
					opacity: 0.6
				}
				ToolButton {
					icon.name: "edit-delete"
					enabled: model.zoneId !== "Local"
					onClicked: removeTimezone(model.zoneId)
					Accessible.name: i18n("Remove time zone")
				}
			}
		}

		ButtonGroup { id: timezoneDisplayType }
		RowLayout {
			Label {
				text: i18n("Display time zone as:")
			}

			RadioButton {
				id: timezoneCityRadio
				text: i18n("Time zone city")
				ButtonGroup.group: timezoneDisplayType
				checked: !page.configBridge.read("displayTimezoneAsCode", true)
				onClicked: page.configBridge.write("displayTimezoneAsCode", false)
			}

			RadioButton {
				id: timezoneCodeRadio
				text: i18n("Time zone code")
				ButtonGroup.group: timezoneDisplayType
				checked: page.configBridge.read("displayTimezoneAsCode", true)
				onClicked: page.configBridge.write("displayTimezoneAsCode", true)
			}
		}
	}
}
