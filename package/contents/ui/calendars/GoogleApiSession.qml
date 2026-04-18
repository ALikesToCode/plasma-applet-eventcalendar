import QtQuick 2.0

import "../lib/Requests.js" as Requests

QtObject {
	id: googleApiSession

	ExecUtil { id: executable }

	property string defaultClientId: "352447874752-sej1ldpd6piqgovtpog0dr91tb4sq5q3.apps.googleusercontent.com"
	property string secretStorePath: plasmoid.file("", "scripts/secret_store.py")

	readonly property string accessToken: plasmoid.configuration.accessToken

	function loadRefreshToken(callback) {
		executable.execArgv([
			"python3",
			secretStorePath,
			"read",
			"--scope",
			"google-session",
			"--key",
			"refresh_token",
		], function(cmd, exitCode, exitStatus, stdout, stderr) {
			var value = (stdout || "").replace(/\n+$/g, "")
			if (exitCode !== 0 && !value) {
				callback(null, "")
				return
			}
			callback(null, value)
		})
	}

	function checkAccessToken(callback) {
		logger.debug("checkAccessToken")
		if (!plasmoid.configuration.accessToken || plasmoid.configuration.accessTokenExpiresAt < Date.now() + 5000) {
			updateAccessToken(callback)
		} else {
			callback(null)
		}
	}

	function updateAccessToken(callback) {
		loadRefreshToken(function(err, refreshToken) {
			if (err || !refreshToken) {
				return callback(err || "No refresh token. Cannot update access token.")
			}
			logger.debug("updateAccessToken")
			fetchNewAccessToken(refreshToken, function(requestErr, data, xhr) {
				if (requestErr || (!requestErr && data && data.error)) {
					logger.log("Error when using refreshToken:", requestErr, data)
					return callback(requestErr)
				}
				logger.debug("onAccessToken", data)
				data = JSON.parse(data)

				googleApiSession.applyAccessToken(data)

				callback(null)
			})
		})
	}

	signal accessTokenError(string msg)
	signal newAccessToken()
	signal transactionError(string msg)

	onTransactionError: logger.log(msg)

	function applyAccessToken(data) {
		plasmoid.configuration.accessToken = data.access_token
		plasmoid.configuration.accessTokenType = data.token_type
		plasmoid.configuration.accessTokenExpiresAt = Date.now() + data.expires_in * 1000
		newAccessToken()
	}

	function fetchNewAccessToken(refreshToken, callback) {
		logger.debug("fetchNewAccessToken")
		Requests.post({
			url: "https://oauth2.googleapis.com/token",
			data: {
				client_id: defaultClientId,
				refresh_token: refreshToken,
				grant_type: "refresh_token",
			},
		}, callback)
	}

	property int errorCount: 0
	function getErrorTimeout(n) {
		return 1000 * Math.min(43200, Math.pow(2, n))
	}

	function delay(delayTime, callback) {
		var timer = Qt.createQmlObject("import QtQuick 2.0; Timer {}", googleCalendarManager)
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
