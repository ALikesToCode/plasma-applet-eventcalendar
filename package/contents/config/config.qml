import QtQuick
import org.kde.plasma.configuration

import "../ui/calendars/PlasmaCalendarUtils.js" as PlasmaCalendarUtils

ConfigModel {
	id: configModel
	property var eventPluginsManager: null

	ConfigCategory {
		name: i18n("General")
		icon: "clock"
		source: "config/ConfigGeneral.qml"
	}
	// ConfigCategory {
	// 	name: i18n("Clock")
	// 	icon: "clock"
	// 	source: "config/ConfigClock.qml"
	// }
	ConfigCategory {
		name: i18n("Layout")
		icon: "grid-rectangular"
		source: "config/ConfigLayout.qml"
	}
	ConfigCategory {
		name: i18n("Timezones")
		icon: "preferences-system-time"
		source: "config/ConfigTimezones.qml"
	}
	ConfigCategory {
		name: i18n("Calendar")
		icon: "view-calendar"
		source: "config/ConfigCalendar.qml"
	}
	ConfigCategory {
		name: i18n("Agenda")
		icon: "view-calendar-agenda"
		source: "config/ConfigAgenda.qml"
	}
	ConfigCategory {
		name: i18n("Events")
		icon: "view-calendar-week"
		source: "config/ConfigEvents.qml"
	}
	ConfigCategory {
		name: i18n("ICalendar (.ics)")
		icon: "text-calendar"
		source: "config/ConfigICal.qml"
		visible: plasmoid.configuration.debugging
	}
	ConfigCategory {
		name: i18n("Google Calendar")
		icon: Qt.resolvedUrl("../icons/google_calendar_96px.png")
		source: "config/ConfigGoogleCalendar.qml"
	}
	ConfigCategory {
		name: i18n("Weather")
		icon: "weather-clear"
		source: "config/ConfigWeather.qml"
	}
	ConfigCategory {
		name: i18n("Advanced")
		icon: "applications-development"
		source: "lib/ConfigAdvanced.qml"
		visible: plasmoid.configuration.debugging
	}

	Component.onCompleted: {
		try {
			eventPluginsManager = Qt.createQmlObject(
				"import org.kde.plasma.workspace.calendar as PlasmaCalendar; PlasmaCalendar.EventPluginsManager {}",
				configModel
			)
		} catch (e) {
			console.warn("[eventcalendar] PlasmaCalendar.EventPluginsManager unavailable:", e)
		}
	}

	property Instantiator __eventPlugins: Instantiator {
		model: eventPluginsManager ? eventPluginsManager.model : null
		delegate: ConfigCategory {
			name: model.display
			icon: model.decoration
			source: model.configUi
			readonly property string pluginFilename: PlasmaCalendarUtils.getPluginFilename(model.pluginPath)
			visible: plasmoid.configuration.enabledCalendarPlugins.indexOf(pluginFilename) > -1
		}

		onObjectAdded: function(index, object) {
			configModel.appendCategory(object)
		}
		onObjectRemoved: function(index, object) {
			configModel.removeCategory(object)
		}
	}
}
