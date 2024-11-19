import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.kirigami 2.20 as Kirigami

PlasmaCore.Dialog {
    id: root
    
    // Plasmoid configuration properties
    property string accessToken: plasmoid.configuration.accessToken
    property string refreshToken: plasmoid.configuration.refreshToken
    property string clientId: plasmoid.configuration.sessionClientId 
    property string clientSecret: plasmoid.configuration.sessionClientSecret
    
    // UI properties
    property bool isLoading: false
    property string statusMessage: ""

    // Main layout
    mainItem: ColumnLayout {
        spacing: Kirigami.Units.smallSpacing

        PlasmaComponents.Label {
            Layout.fillWidth: true
            text: i18n("Google Calendar Integration")
            font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.2
            color: Kirigami.Theme.textColor
        }

        PlasmaComponents.Label {
            Layout.fillWidth: true
            text: statusMessage
            color: Kirigami.Theme.neutralTextColor
            visible: statusMessage !== ""
        }

        PlasmaComponents.Button {
            Layout.fillWidth: true
            text: i18n("Refresh Token")
            icon.name: "view-refresh"
            enabled: !isLoading
            onClicked: updateAccessToken(function(err) {
                if (err) {
                    statusMessage = i18n("Error: %1", err)
                } else {
                    statusMessage = i18n("Token refreshed successfully")
                }
            })
        }

        BusyIndicator {
            Layout.alignment: Qt.AlignHCenter
            running: isLoading
            visible: isLoading
        }
    }

    // Token management functions
    function checkAccessToken(callback) {
        console.debug('Checking Access Token')
        if (plasmoid.configuration.accessTokenExpiresAt < Date.now() + 5000) {
            updateAccessToken(callback)
        } else {
            callback(null)
        }
    }

    function updateAccessToken(callback) {
        if (refreshToken) {
            console.debug('Updating Access Token')
            isLoading = true
            fetchNewAccessToken(function(err, data) {
                isLoading = false
                if (err || (!err && data && data.error)) {
                    console.error('Error when using refreshToken:', err, data)
                    return callback(err)
                }
                console.debug('New Access Token Received', data)
                data = JSON.parse(data)
                applyAccessToken(data)
                callback(null)
            })
        } else {
            callback('No refresh token. Cannot update access token.')
        }
    }

    signal accessTokenError(string msg)
    signal newAccessToken()
    signal transactionError(string msg)

    function applyAccessToken(data) {
        plasmoid.configuration.accessToken = data.access_token
        plasmoid.configuration.accessTokenType = data.token_type
        plasmoid.configuration.accessTokenExpiresAt = Date.now() + data.expires_in * 1000
        newAccessToken()
    }

    function fetchNewAccessToken(callback) {
        console.debug('Fetching New Access Token')
        var url = 'https://www.googleapis.com/oauth2/v4/token'
        Requests.post({
            url: url,
            data: {
                client_id: clientId,
                client_secret: clientSecret,
                refresh_token: refreshToken,
                grant_type: 'refresh_token',
            },
        }, callback)
    }

    property int errorCount: 0
    function getErrorTimeout(n) {
        return 1000 * Math.min(43200, Math.pow(2, n))
    }

    function delay(delayTime, callback) {
        var timer = Qt.createQmlObject("import QtQuick 2.15; Timer {}", root)
        timer.interval = delayTime
        timer.repeat = false
        timer.triggered.connect(callback)
        timer.triggered.connect(function release() {
            timer.triggered.disconnect(callback)
            timer.triggered.disconnect(release)
            timer.destroy()
        })
        timer.start()
    }

    function waitForErrorTimeout(callback) {
        errorCount += 1
        var timeout = getErrorTimeout(errorCount)
        delay(timeout, function() {
            callback()
        })
    }

    Component.onCompleted: {
        // Initial token check
        checkAccessToken(function(err) {
            if (err) {
                statusMessage = i18n("Initial token check failed: %1", err)
            }
        })
    }
}
