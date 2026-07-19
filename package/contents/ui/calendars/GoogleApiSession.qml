import QtQuick

import "../lib/Requests.js" as Requests
import "../lib/GoogleOAuthToken.js" as GoogleOAuthToken

QtObject {
	id: googleApiSession

	property var accountsStore
	property string accountId: ""
	property int accountRevision: 0
	property var connectedStore: null
	property string defaultClientId: "352447874752-sej1ldpd6piqgovtpog0dr91tb4sq5q3.apps.googleusercontent.com"

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

	function readConfig(key, fallback) {
		if (typeof plasmoid !== "undefined" && plasmoid.configuration) {
			var value = plasmoid.configuration[key]
			return (value === undefined || value === null) ? fallback : value
		}
		return fallback
	}

	function normalizedClientValue(value) {
		return value ? String(value).trim() : ""
	}

	function resolveRefreshClientSecret(account) {
		if (!account || account.sessionUsesPkce === true) {
			return ""
		}
		if (account.sessionClientSecret) {
			return normalizedClientValue(account.sessionClientSecret)
		}
		var customClientId = normalizedClientValue(readConfig("customClientId", ""))
		var customClientSecret = normalizedClientValue(readConfig("customClientSecret", ""))
		var latestClientId = normalizedClientValue(readConfig("latestClientId", ""))
		var latestClientSecret = normalizedClientValue(readConfig("latestClientSecret", ""))
		if (account.sessionClientId === customClientId) {
			return customClientSecret
		}
		if (account.sessionClientId === latestClientId && latestClientSecret) {
			return latestClientSecret
		}
		if (account.sessionClientId === defaultClientId) {
			return ""
		}
		return ""
	}

	//--- Refresh Credentials
	function checkAccessToken(callback) {
		logger.debug('checkAccessToken')
		var account = getAccount()
		if (!account) {
			logger.log('checkAccessToken', 'No Google account', accountId)
			return callback('No Google account.')
		}
		if (account.reauthRequired) {
			return callback(GoogleOAuthToken.refreshErrorMessage(null, {
				error: "invalid_grant",
				error_subtype: account.reauthReason || "",
			}))
		}
		if (!account.accessToken && account.refreshToken) {
			updateAccessToken(callback)
			return
		}
		if (!account.accessToken) {
			logger.log('checkAccessToken', 'No refresh token', accountId)
			return callback('No refresh token. Please login again.')
		}
		if (account.accessTokenExpiresAt < Date.now() + 5000) {
			updateAccessToken(callback)
		} else {
			callback(null)
		}
	}

	function updateAccessToken(callback) {
		var account = getAccount()
		if (!(account && account.refreshToken)) {
			logger.log('updateAccessToken', 'No refresh token', accountId)
			callback('No refresh token. Cannot update access token.')
			return
		}
		if (refreshInFlight) {
			refreshCallbacks.push(callback)
			return
		}
		refreshInFlight = true
		refreshCallbacks = [callback]
		logger.debug('updateAccessToken')
		fetchNewAccessToken(function(err, data, xhr) {
			var parsed = GoogleOAuthToken.parseTokenResponse(data)
			if (err || (parsed && parsed.error)) {
				var refreshError = GoogleOAuthToken.refreshErrorMessage(err, parsed)
				var summary = GoogleOAuthToken.errorSummary(parsed)
				logger.logJSON('Error when using refreshToken:', {
					status: xhr ? xhr.status : 0,
					error: summary.error,
					errorSubtype: summary.errorSubtype,
					hasDescription: summary.hasDescription,
				})
				finishRefresh(refreshError)
				if (GoogleOAuthToken.requiresReauthorization(parsed)) {
					markReauthorizationRequired(summary.errorSubtype || summary.error)
				}
				return
			}

			if (!parsed) {
				logger.log('Error parsing Google token refresh response.')
				finishRefresh('Invalid refresh response.')
				return
			}
			if (!parsed.access_token) {
				logger.log('Missing access token in refresh response:', parsed)
				finishRefresh('Missing access token.')
				return
			}

			logger.debugJSON('onAccessToken', {
				tokenType: parsed.token_type || '',
				expiresIn: parsed.expires_in || 0,
				hasAccessToken: !!parsed.access_token,
			})
			var callbacks = refreshCallbacks.slice(0)
			refreshCallbacks = []
			refreshInFlight = false
			googleApiSession.applyAccessToken(parsed)
			for (var i = 0; i < callbacks.length; i++) {
				callbacks[i](null)
			}
		})
	}

	function markReauthorizationRequired(reason) {
		if (!accountsStore || !accountId) {
			return
		}
		accountsStore.updateAccount(accountId, {
			reauthRequired: true,
			reauthReason: reason || "invalid_grant",
		})
	}

	function finishRefresh(err) {
		var callbacks = refreshCallbacks.slice(0)
		refreshCallbacks = []
		refreshInFlight = false
		for (var i = 0; i < callbacks.length; i++) {
			callbacks[i](err)
		}
	}

	signal accessTokenError(string msg)
	signal newAccessToken()
	signal transactionError(string msg)

	property bool refreshInFlight: false
	property var refreshCallbacks: []

	onTransactionError: logger.log(msg)

	function applyAccessToken(data) {
		if (!accountsStore || !accountId) {
			return
		}
		var patch = {
			accessToken: data.access_token,
			accessTokenType: data.token_type,
			accessTokenExpiresAt: Date.now() + data.expires_in * 1000,
		}
		if (data.refresh_token) {
			patch.refreshToken = data.refresh_token
		}
		accountsStore.updateAccount(accountId, patch)
		newAccessToken()
	}

	function fetchNewAccessToken(callback) {
		logger.debug('fetchNewAccessToken')
		var account = getAccount()
		var refreshClientSecret = resolveRefreshClientSecret(account)
		if (account && account.sessionUsesPkce !== true && !refreshClientSecret) {
			return callback('Saved Google session requires a configured client secret. Please login again.')
		}
		var url = 'https://oauth2.googleapis.com/token'
		var data = {
			client_id: account ? account.sessionClientId : "",
			refresh_token: account ? account.refreshToken : "",
			grant_type: 'refresh_token',
		}
		if (refreshClientSecret) {
			data.client_secret = refreshClientSecret
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
