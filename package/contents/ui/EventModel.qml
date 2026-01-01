import QtQuick

import "./calendars"
import "./lib"

CalendarManager {
	id: eventModel

	property var calendarManagerList: []
	property var calendarPluginMap: ({}) // Empty Map
	property var eventsData: { "items": [] }

	Component.onCompleted: {
		bindSignals(plasmaCalendarManager)
	}

	//---
	function fetchingDataListener() { eventModel.asyncRequests += 1 }
	function allDataFetchedListener() { eventModel.asyncRequestsDone += 1 }
	function calendarFetchedListener(calendarId, data) {
		eventModel.setCalendarData(calendarId, data)
	}
	function eventAddedListener(calendarId, data) {
		eventModel.mergeEvents()
		eventModel.eventAdded(calendarId, data)
	}
	function eventCreatedListener(calendarId, data) {
		eventModel.eventCreated(calendarId, data)
	}
	function eventRemovedListener(calendarId, eventId, data) {
		eventModel.mergeEvents()
		eventModel.eventRemoved(calendarId, eventId, data)
	}
	function eventDeletedListener(calendarId, eventId, data) {
		eventModel.eventDeleted(calendarId, eventId, data)
	}
	function eventUpdatedListener(calendarId, eventId, data) {
		eventModel.mergeEvents()
		eventModel.eventUpdated(calendarId, eventId, data)
	}

	function bindSignals(calendarManager) {
		logger.debug('bindSignals', calendarManager)
		calendarManager.fetchingData.connect(fetchingDataListener)
		calendarManager.allDataFetched.connect(allDataFetchedListener)
		calendarManager.calendarFetched.connect(calendarFetchedListener)

		calendarManager.calendarFetched.connect(function(calendarId, data){
			eventModel.calendarPluginMap[calendarId] = calendarManager
		})

		calendarManager.eventAdded.connect(eventAddedListener)
		calendarManager.eventCreated.connect(eventCreatedListener)
		calendarManager.eventRemoved.connect(eventRemovedListener)
		calendarManager.eventDeleted.connect(eventDeletedListener)
		calendarManager.eventUpdated.connect(eventUpdatedListener)
		calendarManager.refresh.connect(deferredUpdate.restart)

		calendarManager.error.connect(error)

		calendarManagerList.push(calendarManager)
	}

	function unbindSignals(calendarManager) {
		var index = calendarManagerList.indexOf(calendarManager)
		if (index >= 0) {
			calendarManagerList.splice(index, 1)
		}
		for (var calendarId in eventModel.calendarPluginMap) {
			if (eventModel.calendarPluginMap[calendarId] === calendarManager) {
				delete eventModel.calendarPluginMap[calendarId]
			}
		}
	}

	function getCalendarManager(calendarId) {
		var calendarKey = calendarId ? "" + calendarId : ""
		var manager = eventModel.calendarPluginMap[calendarKey]
		if (manager) {
			return manager
		}
		for (var i = 0; i < calendarManagerList.length; i++) {
			var calendarManager = calendarManagerList[i]
			if (calendarManager && calendarManager.getCalendar && calendarManager.getCalendar(calendarKey)) {
				eventModel.calendarPluginMap[calendarKey] = calendarManager
				return calendarManager
			}
		}
		if (!calendarKey || calendarKey.indexOf("::") < 0) {
			return null
		}
		var splitIndex = calendarKey.indexOf("::")
		var accountPrefix = calendarKey.slice(0, splitIndex)
		var rawId = calendarKey.slice(splitIndex + 2)
		var calendarCandidate = null
		var taskCandidate = null
		for (var j = 0; j < calendarManagerList.length; j++) {
			var googleManager = calendarManagerList[j]
			if (!googleManager || googleManager.accountId !== accountPrefix || !googleManager.getAccount) {
				continue
			}
			if (googleManager.calendarManagerId === "GoogleCalendar") {
				calendarCandidate = googleManager
			} else if (googleManager.calendarManagerId === "GoogleTasks") {
				taskCandidate = googleManager
			}
			var account = googleManager.getAccount()
			if (googleManager.calendarManagerId === "GoogleCalendar" && account && Array.isArray(account.calendarList)) {
				for (var c = 0; c < account.calendarList.length; c++) {
					var calendar = account.calendarList[c]
					if (rawId === calendar.id || (rawId === "primary" && calendar.primary)) {
						eventModel.calendarPluginMap[calendarKey] = googleManager
						return googleManager
					}
				}
			}
			if (googleManager.calendarManagerId === "GoogleTasks" && account && Array.isArray(account.tasklistList)) {
				for (var t = 0; t < account.tasklistList.length; t++) {
					var tasklist = account.tasklistList[t]
					if (rawId === tasklist.id) {
						eventModel.calendarPluginMap[calendarKey] = googleManager
						return googleManager
					}
				}
			}
		}
		if (calendarCandidate || taskCandidate) {
			var looksLikeCalendar = rawId === "primary" || rawId.indexOf("@") >= 0
			var fallbackManager = looksLikeCalendar ? (calendarCandidate || taskCandidate) : (taskCandidate || calendarCandidate)
			if (fallbackManager) {
				eventModel.calendarPluginMap[calendarKey] = fallbackManager
				return fallbackManager
			}
		}
		return null
	}

	//---
	GoogleAccountsStore {
		id: googleAccountsStore
	}

	ICalManager {
		id: icalManager
		calendarList: appletConfig.icalCalendarList.value
	}

	DebugCalendarManager { id: debugCalendarManager }
	// DebugGoogleCalendarManager { id: debugGoogleCalendarManager }

	Repeater {
		id: googleAccountsRepeater
		model: googleAccountsStore.accounts
		delegate: Item {
			id: googleAccountItem
			property string accountId: modelData.id
			property string accountLabel: modelData.label || ""

			GoogleApiSession {
				id: googleApiSession
				accountsStore: googleAccountsStore
				accountId: googleAccountItem.accountId
			}
			GoogleCalendarManager {
				id: googleCalendarManager
				session: googleApiSession
				accountsStore: googleAccountsStore
				accountId: googleAccountItem.accountId
				accountLabel: googleAccountItem.accountLabel
			}
			GoogleTasksManager {
				id: googleTasksManager
				session: googleApiSession
				accountsStore: googleAccountsStore
				accountId: googleAccountItem.accountId
				accountLabel: googleAccountItem.accountLabel
			}

			Connections {
				target: googleAccountsStore
				function onAccountUpdated(updatedId) {
					if (updatedId === googleAccountItem.accountId) {
						var account = googleAccountsStore.getAccount(updatedId)
						googleAccountItem.accountLabel = account && account.label ? account.label : ""
					}
				}
			}

			Component.onCompleted: {
				eventModel.bindSignals(googleCalendarManager)
				eventModel.bindSignals(googleTasksManager)
			}
			Component.onDestruction: {
				eventModel.unbindSignals(googleCalendarManager)
				eventModel.unbindSignals(googleTasksManager)
			}
		}
	}

	Connections {
		target: googleAccountsStore
		function onAccountsChanged() {
			eventModel.clear()
			deferredUpdate.restart()
		}
	}

	PlasmaCalendarManager {
		id: plasmaCalendarManager
	}

	//---
	property var deferredUpdate: Timer {
		id: deferredUpdate
		interval: 200
		onTriggered: eventModel.update()
	}
	function update() {
		fetchAll()
	}

	onFetchAllCalendars: {
		for (var i = 0; i < calendarManagerList.length; i++) {
			var calendarManager = calendarManagerList[i]
			calendarManager.fetchAll(dateMin, dateMax)
		}
	}

	onAllDataFetched: mergeEvents()

	function mergeEvents() {
		logger.debug('eventModel.mergeEvents')
		delete eventModel.eventsData
		eventModel.eventsData = { items: [] }
		for (var calendarId in eventModel.eventsByCalendar) {
			eventModel.eventsData.items = eventModel.eventsData.items.concat(eventModel.eventsByCalendar[calendarId].items)
		}
	}

	//--- CalendarManager: Event
	function createEvent(calendarId, date, text) {
		if (plasmoid.configuration.agendaNewEventRememberCalendar) {
			plasmoid.configuration.agendaNewEventLastCalendarId = calendarId
		}

		var calendarManager = getCalendarManager(calendarId)
		if (calendarManager) {
			calendarManager.createEvent(calendarId, date, text)
		} else {
			logger.log('Could not createEvent. Could not find calendarManager for calendarId = ', calendarId)
		}
	}

	function deleteEvent(calendarId, eventId) {
		var calendarManager = getCalendarManager(calendarId)
		if (calendarManager) {
			calendarManager.deleteEvent(calendarId, eventId)
		} else {
			logger.log('Could not deleteEvent. Could not find calendarManager for calendarId = ', calendarId)
		}
	}

	function setEventProperty(calendarId, eventId, key, value) {
		logger.debug('eventModel.setEventProperty', calendarId, eventId, key, value)
		var calendarManager = getCalendarManager(calendarId)
		if (calendarManager) {
			calendarManager.setEventProperty(calendarId, eventId, key, value)
		} else {
			logger.log('Could not setEventProperty. Could not find calendarManager for calendarId = ', calendarId)
		}
	}

	function setEventProperties(calendarId, eventId, args) {
		logger.debugJSON('eventModel.setEventProperties', calendarId, eventId, args)
		var calendarManager = getCalendarManager(calendarId)
		if (calendarManager) {
			calendarManager.setEventProperties(calendarId, eventId, args)
		} else {
			logger.log('Could not setEventProperties. Could not find calendarManager for calendarId = ', calendarId)
		}
	}

	//--- CalendarManager: Calendar
	function getCalendarList() {
		var calendarList = []
		for (var i = 0; i < calendarManagerList.length; i++) {
			var calendarManager = calendarManagerList[i]
			var list = calendarManager.getCalendarList()
			// logger.debugJSON(calendarManager.toString(), list)
			for (var j = 0; j < list.length; j++) {
				if (list[j] && list[j].id) {
					eventModel.calendarPluginMap[list[j].id] = calendarManager
				}
			}
			calendarList = calendarList.concat(list)
		}
		return calendarList
	}
}
