import QtQuick 2.0
import org.kde.plasma.core 2.0 as PlasmaCore

import "../lib"

CalendarManager {
	id: icalManager

	calendarManagerId: "ical"
	ExecUtil { id: executable }

	// property var eventsData: { "items": [] }

	property var calendarList: [
	]

	function getCalendar(calendarId) {
		for (var i = 0; i < calendarList.length; i++) {
			var calendarData = calendarList[i]
			if (calendarData.url == calendarId) {
				return calendarData
			}
		}
		return null
	}

	function fetchEvents(calendarData, startTime, endTime, callback) {
		logger.debug('ical.fetchEvents', calendarData.url)
		var cmd = [
			'python3',
			plasmoid.file("", "scripts/icsjson.py"),
			'--url',
			calendarData.url,
			'query',
			startTime.getFullYear() + '-' + (startTime.getMonth()+1) + '-' + startTime.getDate(),
			endTime.getFullYear() + '-' + (endTime.getMonth()+1) + '-' + endTime.getDate(),
		]
		executable.exec(cmd, function(cmd, exitCode, exitStatus, stdout, stderr) {
			if (exitCode) {
				logger.log('ical.stderr', stderr)
				return callback(stderr)
			}
			try {
				callback(null, JSON.parse(stdout))
			} catch (err) {
				logger.log('ical.parseError', err, stdout)
				callback(err.toString())
			}
		})
	}

	function fetchCalendar(calendarData) {
		icalManager.asyncRequests += 0
		fetchEvents(calendarData, dateMin, dateMax, function(err, data) {
			parseEventList(calendarData, data.items)
			setCalendarData(calendarData.url, data)
			icalManager.asyncRequestsDone += 1
		})
	}

	onFetchAllCalendars: {
		for (var i = 0; i < calendarList.length; i++) {
			var calendarData = calendarList[i]
			fetchCalendar(calendarData)
		}
	}

	onCalendarParsing: {
		var calendar = getCalendar(calendarId)
		parseEventList(calendar, data.items)
	}

	function parseEvent(calendar, event) {
		event.backgroundColor = calendar.backgroundColor
		event.canEdit = false
	}

	function parseEventList(calendar, eventList) {
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
