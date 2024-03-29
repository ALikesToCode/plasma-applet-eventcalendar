import QtQuick 2.15
import org.kde.plasma.plasmoid
import "../lib/Requests.js" as Requests

PlasmoidItem {
    id: debugCalendarManager

    property string calendarManagerId: "DebugGoogleCalendar"

    function fetchDebugGoogleSession() {
        if (plasmoid.configuration.accessToken) {
            return
        }
        // Steal accessToken from our current user's config.
        fetchCurrentUserConfig(function(err, metadata) {
            plasmoid.configuration.sessionClientId = metadata['sessionClientId']
            plasmoid.configuration.sessionClientSecret = metadata['sessionClientSecret']
            plasmoid.configuration.accessToken = metadata['accessToken']
            plasmoid.configuration.refreshToken = metadata['refreshToken']
            plasmoid.configuration.accessToken = metadata['accessToken']
            plasmoid.configuration.accessTokenType = metadata['accessTokenType']
            plasmoid.configuration.accessTokenExpiresAt = metadata['accessTokenExpiresAt']
            plasmoid.configuration.calendarIdList = metadata['calendarIdList']
            plasmoid.configuration.calendarList = metadata['calendarList']
            plasmoid.configuration.tasklistIdList = metadata['tasklistIdList']
            plasmoid.configuration.tasklistList = metadata['tasklistList']
            plasmoid.configuration.agendaNewEventLastCalendarId = metadata['agendaNewEventLastCalendarId']
        })
    }

    function fetchCurrentUserConfig(callback) {
        var homePath = Qt.homePath(); // Get the current user's home directory
        var configPath = homePath + "/.config/plasma-org.kde.plasma.desktop-appletsrc";
        Requests.getFile('file://' + configPath, function(err, data) {
            if (err) {
                return callback(err)
            }

            var metadata = Requests.parseMetadata(data)
            callback(null, metadata)
        })
    }

    onFetchAllCalendars: {
        fetchDebugGoogleSession()
    }
}
