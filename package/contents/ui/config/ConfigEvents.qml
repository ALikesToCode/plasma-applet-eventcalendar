import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "../lib"
import "../calendars/PlasmaCalendarUtils.js" as PlasmaCalendarUtils

ConfigPage {
	id: page
	property var eventPluginsManager: null

	HeaderText {
		text: i18n("Event Calendar Plugins")
	}

	ConfigSection {
		CheckBox {
			text: i18n("ICalendar (.ics)")
			checked: true
			enabled: false
			visible: page.configBridge.read("debugging", false)
		}
		CheckBox {
			text: i18n("Google Calendar")
			checked: true
			enabled: false
		}
	}


	HeaderText {
		text: i18n("Plasma Calendar Plugins")
	}

	// From digitalclock's configCalendar.qml
	signal configurationChanged()
	MessageWidget {
		visible: !eventPluginsManager
		messageType: MessageWidget.MessageType.Warning
		closeButtonVisible: false
		text: i18n("Plasma calendar plugins are unavailable. Install the Plasma calendar module to manage these plugins.")
	}
	ConfigSection {
		Repeater {
			id: calendarPluginsRepeater
			model: eventPluginsManager ? eventPluginsManager.model : null
			delegate: CheckBox {
				text: model.display
				checked: model.checked
				onClicked: {
					model.checked = checked // needed for model's setData to be called
					// page.configurationChanged()
					page.saveConfig()
				}
			}
		}
	}
	function saveConfig() {
		if (!eventPluginsManager) {
			return
		}
		page.configBridge.write("enabledCalendarPlugins", PlasmaCalendarUtils.pluginPathToFilenameList(eventPluginsManager.enabledPlugins))
	}
	Component.onCompleted: {
		try {
			eventPluginsManager = Qt.createQmlObject(
				"import org.kde.plasma.calendar as PlasmaCalendar; PlasmaCalendar.EventPluginsManager {}",
				page
			)
		} catch (e) {
			console.warn("[eventcalendar] PlasmaCalendar.EventPluginsManager unavailable:", e)
			return
		}
		PlasmaCalendarUtils.populateEnabledPluginsByFilename(eventPluginsManager, page.configBridge.read("enabledCalendarPlugins", []))
	}

	HeaderText {
		text: i18n("Misc")
	}
	ColumnLayout {

		ConfigSpinBox {
			configKey: 'eventsPollInterval'
			before: i18n("Refresh events every: ")
			suffix: i18nc("Polling interval in minutes", "min")
			minimumValue: 5
			maximumValue: 90
		}
	}

	HeaderText {
		text: i18n("Notifications")
	}

	ConfigSection {
		ConfigNotification {
			label: i18n("Event Reminder")
			notificationEnabledKey: 'eventReminderNotificationEnabled'
			sfxEnabledKey: 'eventReminderSfxEnabled'
			sfxPathKey: 'eventReminderSfxPath'
			sfxPathDefaultValue: '/usr/share/sounds/Oxygen-Im-Nudge.ogg'

			RowLayout {
				spacing: 0
				Item { implicitWidth: parent.parent.indentWidth } // indent
				ConfigSpinBox {
					configKey: 'eventReminderMinutesBefore'
					suffix: i18nc("Polling interval in minutes", "min")
					minimumValue: 1
				}
			}
		}
	}

	ConfigSection {
		ConfigNotification {
			label: i18n("Event Starting")
			notificationEnabledKey: 'eventStartingNotificationEnabled'
			sfxEnabledKey: 'eventStartingSfxEnabled'
			sfxPathKey: 'eventStartingSfxPath'
			sfxPathDefaultValue: '/usr/share/sounds/Oxygen-Im-Nudge.ogg'
		}
	}

}
