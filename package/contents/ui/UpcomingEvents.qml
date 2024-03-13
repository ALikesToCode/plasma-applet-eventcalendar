import QtQuick 2.0
import org.kde.plasma.core as PlasmaCore

import "LocaleFuncs.js" as LocaleFuncs
import "./calendars"

CalendarManager {
    id: upcomingEvents

    property int upcomingEventRange: 90 // minutes
    property int minutesBeforeReminding: plasmoid.configuration.eventReminderMinutesBefore // minutes

    onFetchingData: {
        logger.debug('upcomingEvents.onFetchingData')
    }

    onAllDataFetched: {
        logger.debug('upcomingEvents.onAllDataFetched',
            upcomingEvents.dateMin.toISOString(),
            timeModel.currentTime.toISOString(),
            upcomingEvents.dateMax.toISOString()
        )
        // sendEventListNotification()
    }

    function isUpcomingEvent(eventItem) {
        var dt = eventItem.startDateTime - timeModel.currentTime
        return -30 * 1000 <= dt && dt <= upcomingEventRange * 60 * 1000 // starting within 90 minutes
    }

    function isSameMinute(a, b) {
        return a.getFullYear() === b.getFullYear()
            && a.getMonth() === b.getMonth()
            && a.getDate() === b.getDate()
            && a.getHours() === b.getHours()
            && a.getMinutes() === b.getMinutes()
    }

    function getDeltaMinutes(a1, n) {
        var a2 = new Date(a1)
        a2.setMinutes(a2.getMinutes() + n)
        return a2
    }

    function shouldSendReminder(eventItem) {
        var reminderDateTime = getDeltaMinutes(timeModel.currentTime, minutesBeforeReminding)
        return isSameMinute(reminderDateTime, eventItem.startDateTime)
    }

    function isEventStarting(eventItem) {
        return isSameMinute(timeModel.currentTime, eventItem.startDateTime) // starting this minute
    }

    function isEventInProgress(eventItem) {
        return eventItem.startDateTime <= timeModel.currentTime && timeModel.currentTime < eventItem.endDateTime
    }

    function filterEvents(predicate) {
        var events = []
        for (var calendarId in eventsByCalendar) {
            var calendar = eventsByCalendar[calendarId]
            calendar.items.forEach(function(eventItem) {
                if (predicate(eventItem)) {
                    events.push(eventItem)
                }
            })
        }
        return events
    }

    function formatHeading(heading) {
        var line = ''
        line += '<font size="4"><u>'
        line += heading
        line += '</u></font>'
        return line
    }

    function formatEvent(eventItem) {
        var line = ''
        line += '<font color="' + eventItem.backgroundColor + '">■</font> '
        line += '<b>' + eventItem.summary + ':</b> '
        line += LocaleFuncs.formatEventDuration(eventItem, {
            relativeDate: timeModel.currentTime,
            clock24h: appletConfig.clock24h,
        })
        return line
    }

    function formatEventList(events, heading) {
        var lines = []
        if (events.length > 0 && heading) {
            lines.push(formatHeading(heading))
        }
        events.forEach(function(eventItem) {
            lines.push(formatEvent(eventItem))
        })
        return lines
    }

    function addEventList(lines, heading, events) {
        var newLines = formatEventList(events, heading)
        lines.push.apply(lines, newLines)
    }

    function sendEventListNotification(args) {
        args = args || {}
        var eventsStarting = filterEvents(isEventStarting)
        var eventsInProgress = filterEvents(isEventInProgress)
        var upcomingEvents = filterEvents(isUpcomingEvent)

        var lines = []
        if (args.showEventsStarting !== false) {
            addEventList(lines, i18n("Events Starting"), eventsStarting)
        }
        if (args.showEventInProgress !== false) {
            addEventList(lines, i18n("Events In Progress"), eventsInProgress)
        }
        if (args.showUpcomingEvent !== false) {
            addEventList(lines, i18n("Upcoming Events"), upcomingEvents)
        }

        if (lines.length > 0) {
            var summary = i18n("Calendar")
            var bodyText = lines.join('<br />')

            notificationManager.notify({
                appName: i18n("Event Calendar"),
                appIcon: "view-calendar-upcoming-events",
                summary: summary,
                body: bodyText,
                soundFile: plasmoid.configuration.eventReminderSfxEnabled ? plasmoid.configuration.eventReminderSfxPath : '',
            })
        }
    }

    function checkForEventsStarting() {
        var eventsStarting = filterEvents(isEventStarting)
        var remindersNeeded = filterEvents(shouldSendReminder)

        eventsStarting.forEach(sendEventStartingNotification)
        remindersNeeded.forEach(eventItem => sendEventReminderNotification(eventItem, minutesBeforeReminding))
    }

    function tick() {
        checkForEventsStarting()
    }

    Connections {
        target: eventModel
        function onAllDataFetched() {
            logger.debug('upcomingEvents eventModel.onAllDataFetched', eventModel.dateMin, timeModel.currentTime, eventModel.dateMax)
            upcomingEvents.checkForEventsStarting()
        }
    }

    Connections {
        target: timeModel
        function onMinuteChanged() {
            upcomingEvents.tick()
        }
    }
}
