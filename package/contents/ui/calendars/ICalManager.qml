import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.kirigami 2.20 as Kirigami

import "../lib"

Plasmoid.compactRepresentation: Item {
    id: root
    
    // Configuration properties bound to config values
    property string displayText: Plasmoid.configuration.displayText
    property color textColor: Plasmoid.configuration.useCustomColor ? 
                            Plasmoid.configuration.customColor : 
                            PlasmaCore.Theme.textColor
    property int fontSize: Plasmoid.configuration.fontSize

    Layout.minimumWidth: Kirigami.Units.gridUnit * 10
    Layout.minimumHeight: Kirigami.Units.gridUnit * 4
    
    // Main content layout
    ColumnLayout {
        anchors.fill: parent
        spacing: Kirigami.Units.smallSpacing

        PlasmaComponents3.Label {
            Layout.alignment: Qt.AlignCenter
            text: displayText
            color: textColor
            font.pointSize: fontSize
            
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    // Example of dynamic update
                    displayText = "Clicked at: " + new Date().toLocaleTimeString()
                }
            }
        }

        PlasmaComponents3.Button {
            Layout.alignment: Qt.AlignCenter
            text: i18n("Refresh")
            icon.name: "view-refresh"
            
            onClicked: {
                // Example action
                fetchAllCalendars()
            }
        }

        PlasmaComponents3.ProgressBar {
            Layout.fillWidth: true
            Layout.margins: Kirigami.Units.smallSpacing
            from: 0
            to: 100
            value: asyncRequestsDone / Math.max(1, asyncRequests) * 100
            visible: asyncRequests > 0
        }
    }

    // Calendar manager functionality
    CalendarManager {
        id: icalManager

        calendarManagerId: "ical"
        ExecUtil { id: executable }

        property var calendarList: [
            {
                url: Plasmoid.configuration.defaultCalendarUrl || "/home/user/calendar.ics",
                backgroundColor: Plasmoid.configuration.calendarColor || Kirigami.Theme.highlightColor,
                isTasklist: false,
            }
        ]

        function getCalendar(calendarId) {
            return calendarList.find(calendar => calendar.url === calendarId) || null
        }

        function fetchEvents(calendarData, startTime, endTime, callback) {
            logger.debug('ical.fetchEvents', calendarData.url)
            var cmd = 'python3 ' + plasmoid.file("", "scripts/icsjson.py")
            cmd += ' --url "' + calendarData.url + '"'
            cmd += ' query'
            cmd += ' ' + startTime.getFullYear() + '-' + (startTime.getMonth()+1) + '-' + startTime.getDate()
            cmd += ' ' + endTime.getFullYear() + '-' + (endTime.getMonth()+1) + '-' + endTime.getDate()
            
            executable.exec(cmd, function(cmd, exitCode, exitStatus, stdout, stderr) {
                if (exitCode) {
                    logger.log('ical.stderr', stderr)
                    return callback(stderr)
                }
                callback(null, JSON.parse(stdout))
            })
        }

        function fetchCalendar(calendarData) {
            icalManager.asyncRequests += 1
            fetchEvents(calendarData, dateMin, dateMax, function(err, data) {
                if (!err) {
                    parseEventList(calendarData, data.items)
                    setCalendarData(calendarData.url, data)
                }
                icalManager.asyncRequestsDone += 1
            })
        }

        onFetchAllCalendars: {
            asyncRequests = 0
            asyncRequestsDone = 0
            calendarList.forEach(fetchCalendar)
        }

        onCalendarParsing: {
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
            if (Array.isArray(eventList)) {
                eventList.forEach(event => parseEvent(calendar, event))
            }
        }
    }

    Component.onCompleted: {
        // Initial calendar fetch
        const now = new Date()
        dateMin = new Date(now.getFullYear(), now.getMonth(), 1)
        dateMax = new Date(now.getFullYear(), now.getMonth() + 1, 0)
        icalManager.fetchAllCalendars()
    }
}
