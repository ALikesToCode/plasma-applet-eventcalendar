// Version 4

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami

KCM.SimpleKCM {
	id: page
	Layout.fillWidth: true
	default property alias _contentChildren: content.data
	Layout.fillHeight: true

	// BEGIN AUTO CFG PROPS
	property var cfg_debugging
	property var cfg_debuggingDefault
	property var cfg_pin
	property var cfg_pinDefault
	property var cfg_widgetShowMeteogram
	property var cfg_widgetShowMeteogramDefault
	property var cfg_widgetShowTimer
	property var cfg_widgetShowTimerDefault
	property var cfg_widgetShowAgenda
	property var cfg_widgetShowAgendaDefault
	property var cfg_widgetShowCalendar
	property var cfg_widgetShowCalendarDefault
	property var cfg_timerSfxEnabled
	property var cfg_timerSfxEnabledDefault
	property var cfg_timerSfxFilepath
	property var cfg_timerSfxFilepathDefault
	property var cfg_timerRepeats
	property var cfg_timerRepeatsDefault
	property var cfg_clockFontFamily
	property var cfg_clockFontFamilyDefault
	property var cfg_clockTimeFormat1
	property var cfg_clockTimeFormat1Default
	property var cfg_clockTimeFormat2
	property var cfg_clockTimeFormat2Default
	property var cfg_clockShowLine2
	property var cfg_clockShowLine2Default
	property var cfg_clockLine2HeightRatio
	property var cfg_clockLine2HeightRatioDefault
	property var cfg_clockLineBold1
	property var cfg_clockLineBold1Default
	property var cfg_clockLineBold2
	property var cfg_clockLineBold2Default
	property var cfg_clockMaxHeight
	property var cfg_clockMaxHeightDefault
	property var cfg_clockMouseWheel
	property var cfg_clockMouseWheelDefault
	property var cfg_clockMouseWheelUp
	property var cfg_clockMouseWheelUpDefault
	property var cfg_clockMouseWheelDown
	property var cfg_clockMouseWheelDownDefault
	property var cfg_showOutlines
	property var cfg_showOutlinesDefault
	property var cfg_showBackground
	property var cfg_showBackgroundDefault
	property var cfg_topRowHeight
	property var cfg_topRowHeightDefault
	property var cfg_bottomRowHeight
	property var cfg_bottomRowHeightDefault
	property var cfg_leftColumnWidth
	property var cfg_leftColumnWidthDefault
	property var cfg_rightColumnWidth
	property var cfg_rightColumnWidthDefault
	property var cfg_v72Migration
	property var cfg_v72MigrationDefault
	property var cfg_v71Migration
	property var cfg_v71MigrationDefault
	property var cfg_widget_show_meteogram
	property var cfg_widget_show_meteogramDefault
	property var cfg_widget_show_timer
	property var cfg_widget_show_timerDefault
	property var cfg_widget_show_agenda
	property var cfg_widget_show_agendaDefault
	property var cfg_widget_show_calendar
	property var cfg_widget_show_calendarDefault
	property var cfg_timer_sfx_enabled
	property var cfg_timer_sfx_enabledDefault
	property var cfg_timer_sfx_filepath
	property var cfg_timer_sfx_filepathDefault
	property var cfg_timer_repeats
	property var cfg_timer_repeatsDefault
	property var cfg_clock_fontfamily
	property var cfg_clock_fontfamilyDefault
	property var cfg_clock_timeformat
	property var cfg_clock_timeformatDefault
	property var cfg_clock_timeformat_2
	property var cfg_clock_timeformat_2Default
	property var cfg_clock_line_2
	property var cfg_clock_line_2Default
	property var cfg_clock_line_2_height_ratio
	property var cfg_clock_line_2_height_ratioDefault
	property var cfg_clock_line_1_bold
	property var cfg_clock_line_1_boldDefault
	property var cfg_clock_line_2_bold
	property var cfg_clock_line_2_boldDefault
	property var cfg_clock_maxheight
	property var cfg_clock_maxheightDefault
	property var cfg_clock_mousewheel_up
	property var cfg_clock_mousewheel_upDefault
	property var cfg_clock_mousewheel_down
	property var cfg_clock_mousewheel_downDefault
	property var cfg_show_outlines
	property var cfg_show_outlinesDefault
	property var cfg_selectedTimeZones
	property var cfg_selectedTimeZonesDefault
	property var cfg_displayTimezoneAsCode
	property var cfg_displayTimezoneAsCodeDefault
	property var cfg_monthCurrentCustomTitleFormat
	property var cfg_monthCurrentCustomTitleFormatDefault
	property var cfg_monthShowBorder
	property var cfg_monthShowBorderDefault
	property var cfg_monthShowWeekNumbers
	property var cfg_monthShowWeekNumbersDefault
	property var cfg_monthDayDoubleClick
	property var cfg_monthDayDoubleClickDefault
	property var cfg_monthEventBadgeType
	property var cfg_monthEventBadgeTypeDefault
	property var cfg_monthTodayStyle
	property var cfg_monthTodayStyleDefault
	property var cfg_monthCellRadius
	property var cfg_monthCellRadiusDefault
	property var cfg_firstDayOfWeek
	property var cfg_firstDayOfWeekDefault
	property var cfg_monthHighlightCurrentDayWeek
	property var cfg_monthHighlightCurrentDayWeekDefault
	property var cfg_monthHeightSingleColumn
	property var cfg_monthHeightSingleColumnDefault
	property var cfg_month_show_border
	property var cfg_month_show_borderDefault
	property var cfg_month_show_weeknumbers
	property var cfg_month_show_weeknumbersDefault
	property var cfg_month_eventbadge_type
	property var cfg_month_eventbadge_typeDefault
	property var cfg_month_today_style
	property var cfg_month_today_styleDefault
	property var cfg_month_cell_radius
	property var cfg_month_cell_radiusDefault
	property var cfg_twoColumns
	property var cfg_twoColumnsDefault
	property var cfg_agendaWeatherOnRight
	property var cfg_agendaWeatherOnRightDefault
	property var cfg_agendaWeatherShowIcon
	property var cfg_agendaWeatherShowIconDefault
	property var cfg_agendaWeatherIconHeight
	property var cfg_agendaWeatherIconHeightDefault
	property var cfg_agendaWeatherShowText
	property var cfg_agendaWeatherShowTextDefault
	property var cfg_agendaBreakupMultiDayEvents
	property var cfg_agendaBreakupMultiDayEventsDefault
	property var cfg_agendaNewEventRememberCalendar
	property var cfg_agendaNewEventRememberCalendarDefault
	property var cfg_agendaNewEventLastCalendarId
	property var cfg_agendaNewEventLastCalendarIdDefault
	property var cfg_agendaInProgressColor
	property var cfg_agendaInProgressColorDefault
	property var cfg_agendaFontSize
	property var cfg_agendaFontSizeDefault
	property var cfg_agendaDaySpacing
	property var cfg_agendaDaySpacingDefault
	property var cfg_agendaEventSpacing
	property var cfg_agendaEventSpacingDefault
	property var cfg_agendaMaxDescriptionLines
	property var cfg_agendaMaxDescriptionLinesDefault
	property var cfg_agendaShowEventDescription
	property var cfg_agendaShowEventDescriptionDefault
	property var cfg_agendaShowEventHangoutLink
	property var cfg_agendaShowEventHangoutLinkDefault
	property var cfg_agendaCondensedAllDayEvent
	property var cfg_agendaCondensedAllDayEventDefault
	property var cfg_agendaPlaceOverdueTasksOnToday
	property var cfg_agendaPlaceOverdueTasksOnTodayDefault
	property var cfg_agenda_newevent_remember_calendar
	property var cfg_agenda_newevent_remember_calendarDefault
	property var cfg_agenda_newevent_last_calendar_id
	property var cfg_agenda_newevent_last_calendar_idDefault
	property var cfg_agenda_weather_show_icon
	property var cfg_agenda_weather_show_iconDefault
	property var cfg_agenda_weather_icon_height
	property var cfg_agenda_weather_icon_heightDefault
	property var cfg_agenda_weather_show_text
	property var cfg_agenda_weather_show_textDefault
	property var cfg_agenda_breakup_multiday_events
	property var cfg_agenda_breakup_multiday_eventsDefault
	property var cfg_agenda_inProgressColor
	property var cfg_agenda_inProgressColorDefault
	property var cfg_agenda_fontSize
	property var cfg_agenda_fontSizeDefault
	property var cfg_eventsPollInterval
	property var cfg_eventsPollIntervalDefault
	property var cfg_icalCalendarList
	property var cfg_icalCalendarListDefault
	property var cfg_eventReminderNotificationEnabled
	property var cfg_eventReminderNotificationEnabledDefault
	property var cfg_eventReminderSfxEnabled
	property var cfg_eventReminderSfxEnabledDefault
	property var cfg_eventReminderSfxPath
	property var cfg_eventReminderSfxPathDefault
	property var cfg_eventReminderMinutesBefore
	property var cfg_eventReminderMinutesBeforeDefault
	property var cfg_eventStartingNotificationEnabled
	property var cfg_eventStartingNotificationEnabledDefault
	property var cfg_eventStartingSfxEnabled
	property var cfg_eventStartingSfxEnabledDefault
	property var cfg_eventStartingSfxPath
	property var cfg_eventStartingSfxPathDefault
	property var cfg_enabledCalendarPlugins
	property var cfg_enabledCalendarPluginsDefault
	property var cfg_googleAccounts
	property var cfg_googleAccountsDefault
	property var cfg_googleActiveAccountId
	property var cfg_googleActiveAccountIdDefault
	property var cfg_googleRedirectMode
	property var cfg_googleRedirectModeDefault
	property var cfg_latestClientId
	property var cfg_latestClientIdDefault
	property var cfg_latestClientSecret
	property var cfg_latestClientSecretDefault
	property var cfg_customClientId
	property var cfg_customClientIdDefault
	property var cfg_customClientSecret
	property var cfg_customClientSecretDefault
	property var cfg_sessionClientId
	property var cfg_sessionClientIdDefault
	property var cfg_sessionClientSecret
	property var cfg_sessionClientSecretDefault
	property var cfg_accessToken
	property var cfg_accessTokenDefault
	property var cfg_accessTokenType
	property var cfg_accessTokenTypeDefault
	property var cfg_accessTokenExpiresAt
	property var cfg_accessTokenExpiresAtDefault
	property var cfg_refreshToken
	property var cfg_refreshTokenDefault
	property var cfg_calendarList
	property var cfg_calendarListDefault
	property var cfg_calendarIdList
	property var cfg_calendarIdListDefault
	property var cfg_tasklistList
	property var cfg_tasklistListDefault
	property var cfg_tasklistIdList
	property var cfg_tasklistIdListDefault
	property var cfg_googleEventClickAction
	property var cfg_googleEventClickActionDefault
	property var cfg_googleHideGoalsDesc
	property var cfg_googleHideGoalsDescDefault
	property var cfg_access_token
	property var cfg_access_tokenDefault
	property var cfg_events_pollinterval
	property var cfg_events_pollintervalDefault
	property var cfg_openWeatherMapAppId
	property var cfg_openWeatherMapAppIdDefault
	property var cfg_openWeatherMapCityId
	property var cfg_openWeatherMapCityIdDefault
	property var cfg_weatherCanadaCityId
	property var cfg_weatherCanadaCityIdDefault
	property var cfg_weatherService
	property var cfg_weatherServiceDefault
	property var cfg_weatherUnits
	property var cfg_weatherUnitsDefault
	property var cfg_meteogramHours
	property var cfg_meteogramHoursDefault
	property var cfg_meteogramTextColor
	property var cfg_meteogramTextColorDefault
	property var cfg_meteogramGridColor
	property var cfg_meteogramGridColorDefault
	property var cfg_meteogramRainColor
	property var cfg_meteogramRainColorDefault
	property var cfg_meteogramPositiveTempColor
	property var cfg_meteogramPositiveTempColorDefault
	property var cfg_meteogramNegativeTempColor
	property var cfg_meteogramNegativeTempColorDefault
	property var cfg_meteogramIconColor
	property var cfg_meteogramIconColorDefault
	property var cfg_weather_app_id
	property var cfg_weather_app_idDefault
	property var cfg_weather_city_id
	property var cfg_weather_city_idDefault
	property var cfg_weather_canada_city_id
	property var cfg_weather_canada_city_idDefault
	property var cfg_weather_service
	property var cfg_weather_serviceDefault
	property var cfg_weather_units
	property var cfg_weather_unitsDefault
	property var cfg_meteogram_hours
	property var cfg_meteogram_hoursDefault
	property var cfg_meteogram_textColor
	property var cfg_meteogram_textColorDefault
	property var cfg_meteogram_gridColor
	property var cfg_meteogram_gridColorDefault
	property var cfg_meteogram_rainColor
	property var cfg_meteogram_rainColorDefault
	property var cfg_meteogram_positiveTempColor
	property var cfg_meteogram_positiveTempColorDefault
	property var cfg_meteogram_negativeTempColor
	property var cfg_meteogram_negativeTempColorDefault
	property var cfg_meteogram_iconColor
	property var cfg_meteogram_iconColorDefault
	// END AUTO CFG PROPS

	property QtObject configBridge: QtObject {
		function read(key, fallback) {
			var prop = "cfg_" + key
			if (prop in page) {
				var value = page[prop]
				return typeof value === "undefined" ? fallback : value
			}
			if (typeof plasmoid !== "undefined" && plasmoid.configuration) {
				var directValue = plasmoid.configuration[key]
				return typeof directValue === "undefined" ? fallback : directValue
			}
			return fallback
		}

		function readDefault(key, fallback) {
			var prop = "cfg_" + key + "Default"
			if (prop in page) {
				var value = page[prop]
				return typeof value === "undefined" ? fallback : value
			}
			if (typeof plasmoid !== "undefined" && plasmoid.configuration) {
				var directValue = plasmoid.configuration[key + "Default"]
				return typeof directValue === "undefined" ? fallback : directValue
			}
			return fallback
		}

		function write(key, value) {
			var prop = "cfg_" + key
			if (prop in page) {
				page[prop] = value
			} else if (typeof plasmoid !== "undefined" && plasmoid.configuration) {
				plasmoid.configuration[key] = value
			}
			if (typeof kcm !== "undefined") {
				kcm.needsSave = true
			}
		}
	}


	ColumnLayout {
		id: content
		spacing: Kirigami.Units.smallSpacing

		// Workaround for crash when using default on a Layout.
		// https://bugreports.qt.io/browse/QTBUG-52490
		// Still affecting Qt 5.7.0
		Component.onDestruction: {
			while (children.length > 0) {
				children[children.length - 1].parent = page
			}
		}
	}

	property alias showAppletVersion: appletVersionLoader.active
	Loader {
		id: appletVersionLoader
		active: false
		visible: active
		source: "AppletVersion.qml"
		anchors.right: parent.right
		anchors.bottom: parent.top
	}
}
