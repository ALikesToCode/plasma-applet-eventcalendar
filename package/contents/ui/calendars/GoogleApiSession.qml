import QtQuick

import "../lib/Requests.js" as Requests

QtObject {
	id: googleApiSession

	property var accountsStore
	property string accountId: ""

	readonly property string accessToken: {
		var account = getAccount()
		return account ? account.accessToken : ""
	}

	function getAccount() {
		if (!accountsStore || !accountId) {
			return null
		}
		return accountsStore.getAccount(accountId)
	}

	//--- Refresh Credentials
	function checkAccessToken(callback) {
		logger.debug('checkAccessToken')
		var account = getAccount()
		if (!account || !account.accessToken) {
			return callback('No access token.')
		}
		if (account.accessTokenExpiresAt < Date.now() + 5000) {
			updateAccessToken(callback)
		} else {
			callback(null)
		}
	}

	function updateAccessToken(callback) {
		// logger.debug('accessTokenExpiresAt', plasmoid.configuration.accessTokenExpiresAt)
		// logger.debug('                 now', Date.now())
		// logger.debug('refreshToken', plasmoid.configuration.refreshToken)
		var account = getAccount()
		if (account && account.refreshToken) {
			logger.debug('updateAccessToken')
			fetchNewAccessToken(function(err, data, xhr) {
				if (err || (!err && data && data.error)) {
					logger.log('Error when using refreshToken:', err, data)
					return callback(err)
				}
				logger.debug('onAccessToken', data)
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

	onTransactionError: logger.log(msg)

	function applyAccessToken(data) {
		if (!accountsStore || !accountId) {
			return
		}
		accountsStore.updateAccount(accountId, {
			accessToken: data.access_token,
			accessTokenType: data.token_type,
			accessTokenExpiresAt: Date.now() + data.expires_in * 1000,
		})
		newAccessToken()
	}

	function fetchNewAccessToken(callback) {
		logger.debug('fetchNewAccessToken')
		var account = getAccount()
		var url = 'https://www.googleapis.com/oauth2/v4/token'
		Requests.post({
			url: url,
			data: {
				client_id: account ? account.sessionClientId : "",
				client_secret: account ? account.sessionClientSecret : "",
				refresh_token: account ? account.refreshToken : "",
				grant_type: 'refresh_token',
			},
		}, callback)
	}


	//---
	property int errorCount: 0
	function getErrorTimeout(n) {
		// Exponential Backoff
		// 43200 seconds is 12 hours, which is a reasonable polling limit when the API is down.
		// After 6 errors, we wait an entire minute.
		// After 11 errors, we wait an entire hour.
		// After 15 errors, we will have waited 9 hours.
		// 16 errors and above uses the upper limit of 12 hour intervals.
		return 1000 * Math.min(43200, Math.pow(2, n))
	}
	// https://stackoverflow.com/questions/28507619/how-to-create-delay-function-in-qml
	function delay(delayTime, callback) {
		var timer = Qt.createQmlObject("import QtQuick; Timer {}", googleCalendarManager)
		timer.interval = delayTime
		timer.repeat = false
		timer.triggered.connect(callback)
		timer.triggered.connect(function release(){
			timer.triggered.disconnect(callback)
			timer.triggered.disconnect(release)
			timer.destroy()
		})
		timer.start()
	}
	function waitForErrorTimeout(callback) {
		errorCount += 1
		var timeout = getErrorTimeout(errorCount)
		delay(timeout, function(){
			callback()
		})
	}
}
