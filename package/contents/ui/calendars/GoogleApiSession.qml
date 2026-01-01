import QtQuick

import "../lib/Requests.js" as Requests

QtObject {
	id: googleApiSession

	property var accountsStore
	property string accountId: ""
	property int accountRevision: 0
	property var connectedStore: null

	readonly property string accessToken: {
		// Ensure refreshes propagate when account data updates.
		var _accountId = accountId
		var _ = accountRevision
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
				if (err) {
					logger.log('Error when using refreshToken:', err, data)
					return callback(err)
				}

				var parsed = null
				try {
					parsed = JSON.parse(data)
				} catch (e) {
					logger.log('Error parsing refresh response:', e, data)
					return callback('Invalid refresh response.')
				}

				if (parsed && parsed.error) {
					logger.log('Error when using refreshToken:', parsed)
					return callback(parsed.error_description || parsed.error)
				}
				if (!parsed || !parsed.access_token) {
					logger.log('Missing access token in refresh response:', parsed)
					return callback('Missing access token.')
				}

				logger.debug('onAccessToken', parsed)
				googleApiSession.applyAccessToken(parsed)

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
		var url = 'https://oauth2.googleapis.com/token'
		var data = {
			client_id: account ? account.sessionClientId : "",
			refresh_token: account ? account.refreshToken : "",
			grant_type: 'refresh_token',
		}
		if (account && account.sessionClientSecret) {
			data.client_secret = account.sessionClientSecret
		}
		Requests.post({
			url: url,
			data: data,
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

	function handleAccountUpdated(updatedId) {
		if (updatedId === accountId) {
			accountRevision += 1
		}
	}

	function handleAccountsChanged() {
		accountRevision += 1
	}

	function disconnectStore(store) {
		if (!store) {
			return
		}
		try {
			store.accountUpdated.disconnect(handleAccountUpdated)
		} catch (e) {}
		try {
			store.accountsChanged.disconnect(handleAccountsChanged)
		} catch (e) {}
	}

	function connectStore(store) {
		if (!store) {
			return
		}
		store.accountUpdated.connect(handleAccountUpdated)
		store.accountsChanged.connect(handleAccountsChanged)
	}

	onAccountsStoreChanged: {
		if (connectedStore === accountsStore) {
			return
		}
		disconnectStore(connectedStore)
		connectedStore = accountsStore
		connectStore(connectedStore)
	}

	Component.onCompleted: {
		if (connectedStore !== accountsStore) {
			connectStore(accountsStore)
			connectedStore = accountsStore
		}
	}

	Component.onDestruction: {
		disconnectStore(connectedStore)
		connectedStore = null
	}
}
