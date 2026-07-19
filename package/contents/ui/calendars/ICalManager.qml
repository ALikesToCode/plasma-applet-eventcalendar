import QtQuick

import "../ErrorType.js" as ErrorType
import "../lib"

CalendarManager {
	id: icalManager

	calendarManagerId: "ical"
	ExecUtil { id: executable }
	Logger {
		id: logger
		name: "eventcalendar-ical"
		showDebug: plasmoid.configuration.debugging
	}

	// property var eventsData: { "items": [] }

	property var calendarList: [
	]

	function localFilePath(url) {
		var path = String(url)
		return path.indexOf("file://") === 0 ? path.slice(7) : path
	}

	function getCalendar(calendarId) {
		for (var i = 0; i < calendarList.length; i++) {
			var calendarData = calendarList[i]
			if (calendarData && calendarData.url == calendarId) {
				return calendarData
			}
		}
		return null
	}

	function calendarLabel(calendarData) {
		return String(calendarData && calendarData.name || i18n("iCalendar"))
	}

	function safeProcessError(stderr) {
		var message = String(stderr || i18n("Unknown iCalendar helper error")).trim()
		return message.replace(/https?:\/\/\S+/gi, "[redacted URL]")
	}

	function fetchEvents(calendarData, startTime, endTime, callback) {
		logger.debug('ical.fetchEvents', calendarLabel(calendarData))
		var startDate = startTime.getFullYear() + '-' + (startTime.getMonth() + 1) + '-' + startTime.getDate()
		var endDate = endTime.getFullYear() + '-' + (endTime.getMonth() + 1) + '-' + endTime.getDate()
		var cmd = [
			'python3',
			localFilePath(Qt.resolvedUrl("../../scripts/icsjson.py")),
			'--url',
			calendarData.url,
			'query',
			startDate,
			endDate,
		]
		executable.execArgv(cmd, function(cmd, exitCode, exitStatus, stdout, stderr) {
			if (exitCode) {
				logger.log('ical.fetchError', calendarLabel(calendarData), exitCode, exitStatus)
				return callback(safeProcessError(stderr || stdout))
			}
			var parsed
			try {
				parsed = JSON.parse(stdout)
				if (!(parsed && Array.isArray(parsed.items))) {
					throw new Error("iCalendar helper returned an invalid event list")
				}
			} catch (err) {
				logger.log('ical.parseError', calendarLabel(calendarData), err)
				return callback(err.toString())
			}
			callback(null, parsed)
		})
	}

	function fetchCalendar(calendarData) {
		icalManager.asyncRequests += 1
		fetchEvents(calendarData, dateMin, dateMax, function(err, data) {
			try {
				if (err) {
					icalManager.error(
						i18n("Could not load %1: %2", calendarLabel(calendarData), err),
						ErrorType.UnknownError
					)
					return
				}
				var currentCalendar = getCalendar(calendarData.url)
				if (!currentCalendar || currentCalendar.show === false) {
					return
				}
				setCalendarData(calendarData.url, data)
			} finally {
				icalManager.asyncRequestsDone += 1
			}
		})
	}

	onFetchAllCalendars: {
		for (var i = 0; i < calendarList.length; i++) {
			var calendarData = calendarList[i]
			if (calendarData && calendarData.show !== false && String(calendarData.url || "").trim()) {
				fetchCalendar(calendarData)
			}
		}
	}

	onCalendarParsing: function(calendarId, data) {
		var calendar = getCalendar(calendarId)
		if (calendar) {
			parseEventList(calendar, data.items)
		}
	}

	function parseEvent(calendar, event) {
		event.backgroundColor = calendar.backgroundColor
		event.canEdit = false
	}

	function parseEventList(calendar, eventList) {
		if (!calendar || !Array.isArray(eventList)) {
			return
		}
		eventList.forEach(function(event) {
			parseEvent(calendar, event)
		})
	}

	// onCalendarFetched: {
	// 	console.log(calendarId, data)
	// }

	// Component.onCompleted: {
	// 	var startTime = new Date(2017, 07-1, 01)
	// 	var endTime = new Date(2017, 07-1, 31)
	// 	dateMin = startTime
	// 	dateMax = endTime
	// 	fetchAllCalendars()
	// }
}
