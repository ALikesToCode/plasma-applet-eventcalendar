import QtQuick
import QtTest
import "../package/contents/ui" as Ui
import "../package/contents/ui/calendars" as Calendars
import "CalendarLocaleBindings.js" as Bindings

TestCase {
	id: testCase
	name: "CalendarLocale"
	when: windowShown

	// Only external boundaries are replaced: account persistence and Google replies.
	QtObject {
		id: plasmoid
		property var configuration: ({
			debugging: false,
			googleHideGoalsDesc: true,
			googleEventClickAction: "WebMonthView",
			agendaPlaceOverdueTasksOnToday: false,
			agendaBreakupMultiDayEvents: true
		})
	}
	QtObject {
		id: logger
		function debug() {}
		function debugJSON() {}
		function log() {}
		function logJSON() {}
	}
	function i18n(text) { return text }
	function i18nc(context, text) {
		if (context === "agenda date format line 1") return Bindings.data.dateFormat
		if (context === "agenda date format line 2") return Bindings.data.dayFormat
		return text
	}

	QtObject {
		id: accountStore
		property var account
		signal accountUpdated(string accountId)
		signal accountsChanged()
		function getAccount(accountId) { return account }
		function ensureCalendarSelection(accountId) { return account.calendarIdList }
		function updateAccount(accountId, patch) {
			for (var key in patch) account[key] = patch[key]
			accountUpdated(accountId)
		}
	}
	Calendars.GoogleApiSession {
		id: apiSession
		accountsStore: accountStore
		accountId: "fixture-account"
		property int refreshCount: 0
		function fetchNewAccessToken(callback) {
			refreshCount += 1
			callback(null, {access_token: "fixture-refreshed", token_type: "Bearer", expires_in: 3600})
		}
	}
	Calendars.GoogleCalendarManager {
		id: manager
		session: apiSession
		accountsStore: accountStore
		accountId: "fixture-account"
		property var requests: []
		property int pages: 0
		function fetchGCalEventsPage(args, callback) {
			requests.push({start: args.start, end: args.end, accessToken: args.accessToken})
			pages += 1
			var response = JSON.parse(JSON.stringify(Bindings.data.response))
			if (!args.pageToken) {
				response.items = response.items.slice(0, 3)
				response.nextPageToken = "fixture-page-2"
			} else {
				response.items = response.items.slice(3)
			}
			Qt.callLater(function() { callback(null, response, {status: 200}) })
		}
	}
	QtObject {
		id: timeSource
		property date currentTime: new Date(2026, 9, 1, 12)
	}
	Ui.AgendaModel {
		id: agendaModel
		timeModel: timeSource
		currentMonth: new Date(2026, 9, 1)
		showAllDaysInMonth: false
		showNextNumDays: 0
		clipEventsFromOtherMonths: false
		clipEventsOutsideLimits: false
		parseChunkSize: 2 // Exercise the deferred population path as well.
	}
	SignalSpy { id: fetched; target: manager; signalName: "allDataFetched" }
	SignalSpy { id: errors; target: manager; signalName: "error" }
	QtObject {
		id: clock
		property date currentTime: new Date(2026, 9, 28, 9, 30)
	}
	Repeater {
		id: agendaRows
		model: agendaModel
		delegate: Item {
			property string dateText: testCase.evaluateDate(date, Bindings.data.dateExpression)
			property string dayText: testCase.evaluateDate(date, Bindings.data.dayExpression)
			property date agendaItemDate: model.date
			property string fullDateText: testCase.evaluateFullDate(agendaItemDate)
			property alias eventLabels: eventLabels
			Repeater {
				id: eventLabels
				model: events
				Text { text: summary }
			}
		}
	}

	function init() {
		manager.clear()
		manager.requests = []
		manager.pages = 0
		fetched.clear()
		errors.clear()
		agendaModel.clear()
		accountStore.account = {
			id: "fixture-account",
			accessToken: "fixture-access-token",
			refreshToken: "fixture-refresh-token",
			accessTokenExpiresAt: Date.now() + 3600000,
			sessionClientId: "fixture-client",
			sessionUsesPkce: true,
			calendarSelectionInitialized: true,
			calendarIdList: ["fixture-calendar"],
			calendarList: [{id: "fixture-calendar", summary: "Testkalender", accessRole: "owner", backgroundColor: "#123456"}]
		}
		apiSession.refreshCount = 0
	}
	function loadEvents() {
		manager.fetchAll(new Date(2026, 9, 1), new Date(2026, 10, 1))
		tryCompare(fetched, "count", 1)
		compare(errors.count, 0)
		var data = manager.eventsByCalendar["fixture-account::fixture-calendar"]
		verify(!!data, "The fetched calendar must reach the manager's event store")
		compare(data.items.length, 7)
		agendaModel.parseGCalEvents(data)
		tryCompare(agendaModel, "populating", false)
		return data
	}
	function eventById(data, id) {
		for (var i = 0; i < data.items.length; i++) if (data.items[i].id === id) return data.items[i]
		fail("Missing event: " + id)
	}
	function evaluateDate(date, expression) {
		// Evaluate the checked-out production binding with the real QML Date role.
		return eval(expression)
	}
	function evaluateFullDate(agendaItemDate) {
		return eval("(function() {" + Bindings.data.fullDateBody + "})()")
	}
	function evaluateClock(timeFormat, expression) { return eval(expression) }

	function test_german_timezone_and_active_locale() {
		compare(Qt.locale().name, Bindings.data.localeName)
		compare(new Date(2026, 9, 24, 12).getTimezoneOffset(), -120)
		compare(new Date(2026, 9, 28, 12).getTimezoneOffset(), -60)
	}
	function test_paginated_fetch_and_agenda_dates() {
		var data = loadEvents()
		compare(manager.pages, 2)
		compare(manager.requests[0].start, "2026-09-30T22:00:00.000Z")
		compare(manager.requests[0].end, "2026-10-31T23:00:00.000Z")
		compare(agendaModel.count, 4)
		var days = []
		var counts = []
		for (var i = 0; i < agendaModel.count; i++) {
			var row = agendaModel.get(i)
			days.push(row.date.getDate())
			counts.push(row.events.count)
		}
		compare(days.join(","), "24,25,26,28")
		compare(counts.join(","), "1,3,1,4")
		compare(eventById(data, "timed").startDateTime.getHours(), 9)
		compare(eventById(data, "utc-midnight").startDateTime.getDate(), 28)
		compare(eventById(data, "all-day").startDateTime.getHours(), 0)
		compare(eventById(data, "all-day").endDateTime.getDate(), 29)
		compare(eventById(data, "recurrence-instance").canEdit, false)
		var summer = eventById(data, "dst-summer").startDateTime
		var winter = eventById(data, "dst-winter").startDateTime
		compare(summer.getHours(), 2)
		compare(winter.getHours(), 2)
		compare(winter - summer, 3600000)
	}
	function test_localized_agenda_and_clock_labels() {
		loadEvents()
		var row = agendaModel.get(3)
		var expectations = {
			de_DE: {date: "28 Okt.", day: "Mi.", fullDay: "Mittwoch"},
			en_US: {date: "Oct 28", day: "Wed", fullDay: "Wednesday"},
			ru_RU: {date: "окт. 28", day: "ср", fullDay: "среда"}
		}[Bindings.data.localeName]
		compare(agendaRows.count, 4)
		var displayedRow = agendaRows.itemAt(3)
		compare(displayedRow.dateText, expectations.date)
		compare(displayedRow.dayText, expectations.day)
		verify(displayedRow.fullDateText.indexOf(expectations.fullDay) >= 0)
		compare(displayedRow.eventLabels.count, 4)
		var summaries = []
		for (var eventIndex = 0; eventIndex < displayedRow.eventLabels.count; eventIndex++) {
			summaries.push(displayedRow.eventLabels.itemAt(eventIndex).text)
		}
		verify(summaries.indexOf("Gespräch über Förderung") >= 0)
		verify(summaries.indexOf("Ganztägiger Termin") >= 0)
		for (var i = 0; i < Bindings.data.clockExpressions.length; i++) {
			compare(evaluateClock("hh:mm", Bindings.data.clockExpressions[i]), "09:30")
			compare(evaluateClock("ddd", Bindings.data.clockExpressions[i]), expectations.day)
		}
		// Formatting must leave the stored instants and agenda entries intact.
		compare(row.date.getDate(), 28)
		compare(row.events.count, 4)
	}
	function test_expired_token_is_refreshed_before_fetching() {
		accountStore.account.accessTokenExpiresAt = 0
		loadEvents()
		compare(apiSession.refreshCount, 1)
		compare(manager.requests[0].accessToken, "fixture-refreshed")
	}
	function test_reauthorization_error_is_independent_of_locale() {
		accountStore.account.reauthRequired = true
		manager.fetchAll(new Date(2026, 9, 1), new Date(2026, 10, 1))
		compare(manager.pages, 0)
		compare(errors.count, 1)
		verify(fetched.count >= 1)
	}
	function test_intentionally_unselected_calendars_fetch_no_events() {
		accountStore.account.calendarIdList = []
		manager.fetchAll(new Date(2026, 9, 1), new Date(2026, 10, 1))
		compare(manager.pages, 0)
		compare(errors.count, 0)
		compare(Object.keys(manager.eventsByCalendar).length, 0)
	}
}
