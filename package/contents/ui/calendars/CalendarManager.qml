import QtQuick 2.15
import org.kde.plasma.plasmoid 2.0
import org.kde.kirigami 2.20 as Kirigami
import org.kde.plasma.core 2.1 as PlasmaCore

PlasmoidItem {
    id: calendarManager

    property string calendarManagerId: ""
    property var eventsByCalendar: ({}) // { "": { "items": [] } }

    property date dateMin: new Date()
    property date dateMax: new Date()

    property bool clearingData: false
    property int asyncRequests: 0
    property int asyncRequestsDone: 0

    // Signals for async operations and data management
    signal refresh()
    signal dataCleared()
    signal fetchingData()
    signal calendarFetched(string calendarId, var data)
    signal allDataFetched()
    signal eventAdded(string calendarId, var data)
    signal eventCreated(string calendarId, var data)
    signal eventRemoved(string calendarId, string eventId, var data)
    signal eventDeleted(string calendarId, string eventId, var data)
    signal eventUpdated(string calendarId, string eventId, var data)
    signal error(string msg, int errorType)

    // Monitor async request completion
    onAsyncRequestsDoneChanged: {
        if (!clearingData && asyncRequestsDone >= asyncRequests) {
            allDataFetched()
        }
    }

    //--- Calendar Management ---
    function getCalendarList() {
        return [] // Base implementation - should be overridden
    }

    function getCalendar(calendarId) {
        return getCalendarList().find(calendar => calendar.id === calendarId) || null
    }

    //--- Calendar Data Management ---
    function setCalendarData(calendarId, data) {
        if (!calendarId || !data) {
            console.warn("Invalid calendar data:", calendarId, data)
            return
        }
        
        calendarParsing(calendarId, data)
        eventsByCalendar[calendarId] = data
        calendarFetched(calendarId, data)
    }

    function clear() {
        console.debug(`${calendarManager}: Clearing calendar data`)
        clearingData = true
        asyncRequests = 0
        asyncRequestsDone = 0
        eventsByCalendar = {}
        clearingData = false
        dataCleared()
    }

    //--- Event Management ---
    function getEvent(calendarId, eventId) {
        const calendar = eventsByCalendar[calendarId]
        if (!calendar || !calendar.items) return null
        return calendar.items.find(event => event.id === eventId)
    }

    function addEvent(calendarId, data) {
        if (!eventsByCalendar[calendarId]) {
            console.warn("Calendar not found:", calendarId)
            return
        }
        eventsByCalendar[calendarId].items.push(data)
        eventAdded(calendarId, data)
    }

    function removeEvent(calendarId, eventId) {
        console.debug(`${calendarManager}: Removing event`, calendarId, eventId)
        const calendar = eventsByCalendar[calendarId]
        if (!calendar || !calendar.items) {
            console.warn("Calendar or events not found:", calendarId)
            return
        }

        const index = calendar.items.findIndex(event => event.id === eventId)
        if (index === -1) {
            console.warn("Event not found:", eventId)
            return
        }

        const removedEvent = calendar.items.splice(index, 1)[0]
        eventRemoved(calendarId, eventId, removedEvent)
    }

    //--- Data Fetching ---
    function fetchAll(dateMin, dateMax) {
        console.debug(`${calendarManager}: Fetching all events`, dateMin, dateMax)
        fetchingData()
        clear()
        
        if (dateMin instanceof Date && dateMax instanceof Date) {
            calendarManager.dateMin = dateMin
            calendarManager.dateMax = dateMax
        }
        
        fetchAllCalendars()
    }

    // Implementation signals
    signal fetchAllCalendars()
    signal calendarParsing(string calendarId, var data)
    signal eventParsing(string calendarId, var event)

    onCalendarParsing: {
        if (!data || !data.items) {
            console.warn("Invalid calendar data structure")
            return
        }
        data.items.forEach(event => {
            eventParsing(calendarId, event)
            defaultEventParsing(calendarId, event)
        })
    }

    function defaultEventParsing(calendarId, event) {
        if (!event) return

        event.calendarManagerId = calendarManagerId
        event.calendarId = calendarId

        event._summary = event.summary
        event.summary = event.summary || i18nc("event with no summary", "(No title)")

        // Parse dates consistently
        try {
            event.startDateTime = event.start.date ? 
                new Date(event.start.date + 'T00:00:00') :
                new Date(event.start.dateTime)

            event.endDateTime = event.end.date ?
                new Date(event.end.date + 'T00:00:00') :
                new Date(event.end.dateTime)
        } catch (e) {
            console.error("Date parsing error:", e)
            error("Failed to parse event dates", 1)
        }
    }

    function parseSingleEvent(calendarId, event) {
        if (!event) return
        calendarParsing(calendarId, { items: [event] })
    }

    //--- Event Modification Stubs ---
    function createEvent(calendarId, date, text) {
        console.warn(`${calendarManager}: createEvent not implemented`)
    }

    function deleteEvent(calendarId, eventId) {
        console.warn(`${calendarManager}: deleteEvent not implemented`)
    }

    function setEventProperty(calendarId, eventId, key, value) {
        console.warn(`${calendarManager}: setEventProperty not implemented`)
    }

    function setEventProperties(calendarId, eventId, args) {
        console.warn(`${calendarManager}: setEventProperties not implemented`)
    }
}
