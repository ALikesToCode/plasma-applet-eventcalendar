import QtQuick 2.15
import QtQuick.Layouts 1.15
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.1 as PlasmaCore
import org.kde.kirigami 2.20 as Kirigami
import org.kde.plasma.components 3.0 as PlasmaComponents3

import "../Shared.js" as Shared
import "../lib/Requests.js" as Requests
import "../code/DebugFixtures.js" as DebugFixtures

PlasmoidItem {
    id: debugCalendarManager

    property string calendarManagerId: "debug"
    property var debugCalendar: null
    property bool isLoading: false

    Plasmoid.backgroundHints: PlasmaCore.Types.StandardBackground
    Plasmoid.configurationRequired: !debugCalendar

    // UI Layout
    contentItem: ColumnLayout {
        spacing: Kirigami.Units.smallSpacing

        PlasmaComponents3.Label {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: i18n("Debug Calendar")
            font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.2
            color: Kirigami.Theme.textColor
        }

        PlasmaComponents3.BusyIndicator {
            Layout.alignment: Qt.AlignCenter
            running: isLoading
            visible: isLoading
        }

        PlasmaComponents3.Button {
            Layout.alignment: Qt.AlignCenter
            text: i18n("Load Debug Events")
            icon.name: "view-refresh"
            enabled: !isLoading
            onClicked: fetchDebugEvents()
        }

        PlasmaComponents3.Label {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: debugCalendar ? i18n("Calendar Loaded") : i18n("No Calendar Data")
            color: Kirigami.Theme.textColor
        }
    }

    function fetchDebugEvents() {
        isLoading = true
        plasmoid.configuration.debugging = true
        debugCalendar = DebugFixtures.getCalendar()
        var debugEventData = DebugFixtures.getEventData()
        setCalendarData(debugCalendar.id, debugEventData)
        isLoading = false
    }

    function getCalendarList() {
        return debugCalendar ? [debugCalendar] : []
    }

    function createEvent(calendarId, date, text) {
        var summary = text
        var start = {
            date: Shared.dateString(date),
            dateTime: date,
        }
        var endDate = new Date(date.getFullYear(), date.getMonth(), date.getDate() + 1, 0, 0, 0)
        var end = {
            date: Shared.dateString(endDate),
            dateTime: endDate,
        }
        var description = ''
        var data = DebugFixtures.createEvent(summary, start, end, description)
        parseSingleEvent(calendarId, data)
        addEvent(calendarId, data)
        eventCreated(calendarId, data)
    }

    function deleteEvent(calendarId, eventId) {
        var data = getEvent(calendarId, eventId)
        removeEvent(calendarId, eventId)
        eventDeleted(calendarId, eventId, data)
    }

    function parseEvent(calendar, event) {
        event.description = event.description || ""
        event.backgroundColor = calendar.backgroundColor
        event.canEdit = true
    }

    function parseEventList(calendar, eventList) {
        eventList.forEach(function(event) {
            parseEvent(calendar, event)
        })
    }

    onCalendarParsing: {
        parseEventList(debugCalendar, data.items)
    }

    function setEventProperty(calendarId, eventId, key, value) {
        var event = getEvent(calendarId, eventId)
        if (!event) {
            console.warn('Error: Trying to update non-existent event')
            return
        }
        event[key] = value
        eventUpdated(calendarId, eventId, event)
    }

    function setEventProperties(calendarId, eventId, args) {
        Object.keys(args).forEach(key => {
            setEventProperty(calendarId, eventId, key, args[key])
        })
    }
}
