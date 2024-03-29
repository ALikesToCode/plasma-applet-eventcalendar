import QtQuick 2.15

QtObject {
    id: googleApiSession

    property string accessToken: plasmoid.configuration.accessToken

    // Refresh Credentials
    function checkAccessToken(callback) {
        console.debug('Checking Access Token')
        if (plasmoid.configuration.accessTokenExpiresAt < Date.now() + 5000) {
            updateAccessToken(callback)
        } else {
            callback(null)
        }
    }

    function updateAccessToken(callback) {
        if (plasmoid.configuration.refreshToken) {
            console.debug('Updating Access Token')
            fetchNewAccessToken(function(err, data) {
                if (err || (!err && data && data.error)) {
                    console.error('Error when using refreshToken:', err, data)
                    return callback(err)
                }
                console.debug('New Access Token Received', data)
                data = JSON.parse(data)

                googleApiSession.applyAccessToken(data)

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
                client_id: plasmoid.configuration.sessionClientId,
                client_secret: plasmoid.configuration.sessionClientSecret,
                refresh_token: plasmoid.configuration.refreshToken,
                grant_type: 'refresh_token',
            },
        }, callback)
    }

    property int errorCount: 0
    function getErrorTimeout(n) {
        return 1000 * Math.min(43200, Math.pow(2, n))
    }

    function delay(delayTime, callback) {
        var timer = Qt.createQmlObject("import QtQuick 2.15; Timer {}", googleApiSession)
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
}
