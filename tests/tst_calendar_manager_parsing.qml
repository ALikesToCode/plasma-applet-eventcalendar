import QtQuick
import QtTest
import "../package/contents/ui/calendars" as Calendars

// Run: qmltestrunner -input tests/tst_calendar_manager_parsing.qml (Qt 6)
TestCase {
	id: testCase
	name: "CalendarManagerParsing"

	QtObject {
		id: logger
		function debug() {}
		function debugJSON() {}
		function log() {}
		function logJSON() {}
	}
	function i18nc(context, text) { return text }

	Calendars.CalendarManager {
		id: manager
		calendarManagerId: "fixture"
		function parseCalendarEvents(calendarId, data) {
			data.items.forEach(function(event) {
				event.backgroundColor = "#123456"
				event.parsedAfterDefaults = event.startDateTime instanceof Date
			})
		}
	}
	SignalSpy { id: fetched; target: manager; signalName: "calendarFetched" }

	function init() {
		manager.clear()
		fetched.clear()
	}

	function timedEvent(id) {
		return {
			id: id,
			summary: "Timed",
			start: { dateTime: "2026-10-28T08:30:00Z" },
			end: { dateTime: "2026-10-28T09:30:00Z" },
		}
	}

	function test_setCalendarData_parses_the_stored_events() {
		var data = {
			items: [
				timedEvent("timed"),
				{ id: "all-day", start: { date: "2026-10-28" }, end: { date: "2026-10-29" } },
			],
		}
		manager.setCalendarData("fixture-calendar", data)

		var stored = manager.eventsByCalendar["fixture-calendar"]
		verify(stored === data, "the manager must keep the caller's object")
		var timed = stored.items[0]
		verify(timed.startDateTime instanceof Date, "startDateTime must be set on the stored event")
		compare(timed.startDateTime.getTime(), Date.UTC(2026, 9, 28, 8, 30))
		compare(timed.endDateTime.getTime(), Date.UTC(2026, 9, 28, 9, 30))
		compare(timed.calendarId, "fixture-calendar")
		compare(timed.calendarManagerId, "fixture")
		compare(timed.backgroundColor, "#123456")
		compare(timed.parsedAfterDefaults, true, "implementations run after the default parsing")

		var allDay = stored.items[1]
		compare(allDay.summary, "(No title)")
		compare(allDay.startDateTime.getTime(), new Date(2026, 9, 28).getTime())
		compare(allDay.endDateTime.getTime(), new Date(2026, 9, 29).getTime())
		compare(fetched.count, 1)
	}

	function test_parseSingleEvent_updates_the_event() {
		var event = timedEvent("created")
		manager.parseSingleEvent("fixture-calendar", event)
		verify(event.startDateTime instanceof Date)
		compare(event.endDateTime.getTime(), Date.UTC(2026, 9, 28, 9, 30))
		compare(event.backgroundColor, "#123456")
	}
}
