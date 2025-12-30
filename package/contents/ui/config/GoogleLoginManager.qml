import QtQuick

import "../lib"
import "../lib/ConfigUtils.js" as ConfigUtils
import "../lib/Requests.js" as Requests

Item {
	id: session

	Logger {
		id: logger
		showDebug: readConfig("debugging", false)
	}

	GoogleAccountsStore {
		id: accountsStore
	}

	property var accounts: []
	property string activeAccountId: accountsStore.activeAccountId
	property var activeAccount: null

	readonly property bool isLoggedIn: accounts && accounts.length > 0
	readonly property bool needsRelog: {
		if (!activeAccount) {
			return false
		}
		if (activeAccount.accessToken && activeAccount.sessionClientId != effectiveClientId) {
			return true
		}
		return false
	}

	readonly property var calendarList: activeAccount ? (activeAccount.calendarList || []) : []
	readonly property var calendarIdList: activeAccount ? (activeAccount.calendarIdList || []) : []
	readonly property var tasklistList: activeAccount ? (activeAccount.tasklistList || []) : []
	readonly property var tasklistIdList: activeAccount ? (activeAccount.tasklistIdList || []) : []

	property string redirectUri: "http://127.0.0.1:53682/"
	property var configBridge: null
	function normalizedClientValue(value) {
		return value ? value.trim() : ""
	}
	readonly property string effectiveClientId: normalizedClientValue(readConfig("customClientId", "")) || readConfig("latestClientId", "")
	readonly property string effectiveClientSecret: normalizedClientValue(readConfig("customClientSecret", "")) || readConfig("latestClientSecret", "")

	Connections {
		target: accountsStore
		function onAccountsChanged() {
			session.accounts = accountsStore.accounts.slice(0)
			session.refreshActiveAccount()
		}
		function onAccountUpdated(accountId) {
			session.accounts = accountsStore.accounts.slice(0)
			if (accountId === session.activeAccountId) {
				session.refreshActiveAccount()
			}
		}
		function onActiveAccountIdChanged() {
			session.activeAccountId = accountsStore.activeAccountId
			session.refreshActiveAccount()
		}
	}

	Component.onCompleted: {
		configBridge = ConfigUtils.findBridge(session)
		session.accounts = accountsStore.accounts.slice(0)
		refreshActiveAccount()
	}

	function readConfig(key, fallback) {
		if (configBridge) {
			var bridged = configBridge.read(key, fallback)
			return (bridged === undefined || bridged === null) ? fallback : bridged
		}
		if (typeof plasmoid !== "undefined" && plasmoid.configuration) {
			var directValue = plasmoid.configuration[key]
			return (directValue === undefined || directValue === null) ? fallback : directValue
		}
		return fallback
	}

	function writeConfig(key, value) {
		if (configBridge) {
			configBridge.write(key, value)
			return
		}
		if (typeof plasmoid !== "undefined" && plasmoid.configuration) {
			plasmoid.configuration[key] = value
			if (typeof kcm !== "undefined") {
				kcm.needsSave = true
			}
		}
	}

	function refreshActiveAccount() {
		activeAccount = accountsStore.getAccount(activeAccountId)
	}

	//--- Signals
	signal newAccessToken()
	signal sessionReset()
	signal error(string err)

	//---
	readonly property string authorizationCodeUrl: {
		var url = 'https://accounts.google.com/o/oauth2/v2/auth'
		url += '?scope=' + encodeURIComponent('https://www.googleapis.com/auth/calendar https://www.googleapis.com/auth/tasks')
		url += '&response_type=code'
		url += '&redirect_uri=' + encodeURIComponent(redirectUri)
		url += '&access_type=offline'
		url += '&prompt=consent'
		url += '&client_id=' + encodeURIComponent(effectiveClientId)
		return url
	}

	function setActiveAccountId(accountId) {
		accountsStore.setActiveAccountId(accountId)
	}

	function setCalendarIdList(list) {
		if (activeAccountId) {
			accountsStore.updateAccount(activeAccountId, { calendarIdList: list })
		}
	}

	function setTasklistIdList(list) {
		if (activeAccountId) {
			accountsStore.updateAccount(activeAccountId, { tasklistIdList: list })
		}
	}

	function removeAccount(accountId) {
		logout(accountId)
	}

	function extractAuthorizationCode(input) {
		if (!input) {
			return ""
		}
		var trimmed = input.trim()
		var match = /[?&]code=([^&]+)/.exec(trimmed)
		if (match && match[1]) {
			return decodeURIComponent(match[1].replace(/\+/g, ' '))
		}
		return trimmed
	}

	function fetchAccessToken(args) {
		var authCode = extractAuthorizationCode(args.authorizationCode)
		if (!authCode) {
			handleError('Invalid Google Authorization Code', null)
			return
		}
		var url = 'https://oauth2.googleapis.com/token'
		Requests.post({
			url: url,
			data: {
				client_id: effectiveClientId,
				client_secret: effectiveClientSecret,
				code: authCode,
				grant_type: 'authorization_code',
				redirect_uri: redirectUri,
			},
		}, function(err, data, xhr) {
			logger.debug('/oauth2/v4/token Response', data)

			// Check for errors
			if (err) {
				handleError(err, null)
				return
			}
			try {
				data = JSON.parse(data)
			} catch (e) {
				handleError('Error parsing /oauth2/v4/token data as JSON', null)
				return
			}
			if (data && data.error) {
				handleError(err, data)
				return
			}

			// Ready
			updateAccessToken(data, args.accountId)
		})
	}

	function updateAccessToken(data, accountId) {
		var account = accountId ? accountsStore.getAccount(accountId) : null
		var targetId = accountId
		if (!account) {
			var created = accountsStore.addAccount({
				label: '',
			})
			targetId = created.id
		}
		accountsStore.updateAccount(targetId, {
			sessionClientId: effectiveClientId,
			sessionClientSecret: effectiveClientSecret,
			accessToken: data.access_token,
			accessTokenType: data.token_type,
			accessTokenExpiresAt: Date.now() + data.expires_in * 1000,
			refreshToken: data.refresh_token || (account && account.refreshToken) || '',
		})
		accountsStore.setActiveAccountId(targetId)
		newAccessToken()
	}

	onNewAccessToken: updateData()

	function updateData() {
		updateCalendarList()
		updateTasklistList()
	}

	function updateCalendarList() {
		logger.debug('updateCalendarList')
		if (!activeAccount || !activeAccount.accessToken) {
			return
		}
		fetchGCalCalendars({
			accessToken: activeAccount.accessToken,
		}, function(err, data, xhr) {
			// Check for errors
			if (err || data.error) {
				handleError(err, data)
				return
			}
			var label = deriveLabelFromCalendars(data.items)
			var patch = { calendarList: data.items }
			if (label && !activeAccount.label) {
				patch.label = label
			}
			accountsStore.updateAccount(activeAccountId, patch)
		})
	}

	function fetchGCalCalendars(args, callback) {
		var url = 'https://www.googleapis.com/calendar/v3/users/me/calendarList'
		Requests.getJSON({
			url: url,
			headers: {
				"Authorization": "Bearer " + args.accessToken,
			}
		}, function(err, data, xhr) {
			// console.log('fetchGCalCalendars.response', err, data, xhr && xhr.status)
			if (!err && data && data.error) {
				return callback('fetchGCalCalendars error', data, xhr)
			}
			logger.debugJSON('fetchGCalCalendars.response.data', data)
			callback(err, data, xhr)
		})
	}

	function updateTasklistList() {
		logger.debug('updateTasklistList')
		if (!activeAccount || !activeAccount.accessToken) {
			return
		}
		fetchGoogleTasklistList({
			accessToken: activeAccount.accessToken,
		}, function(err, data, xhr) {
			// Check for errors
			if (err || data.error) {
				handleError(err, data)
				return
			}
			accountsStore.updateAccount(activeAccountId, { tasklistList: data.items })
		})
	}

	function fetchGoogleTasklistList(args, callback) {
		var url = 'https://www.googleapis.com/tasks/v1/users/@me/lists'
		Requests.getJSON({
			url: url,
			headers: {
				"Authorization": "Bearer " + args.accessToken,
			}
		}, function(err, data, xhr) {
			console.log('fetchGoogleTasklistList.response', err, data, xhr && xhr.status)
			if (!err && data && data.error) {
				return callback('fetchGoogleTasklistList error', data, xhr)
			}
			logger.debugJSON('fetchGoogleTasklistList.response.data', data)
			callback(err, data, xhr)
		})
	}

	function logout(accountId) {
		var targetId = accountId || activeAccountId
		if (!targetId) {
			return
		}
		accountsStore.removeAccount(targetId)

		var lastCalendarId = readConfig("agendaNewEventLastCalendarId", "")
		if (lastCalendarId.indexOf(targetId + '::') === 0) {
			writeConfig("agendaNewEventLastCalendarId", "")
		}
		sessionReset()
	}

	function deriveLabelFromCalendars(list) {
		if (!Array.isArray(list)) {
			return ''
		}
		for (var i = 0; i < list.length; i++) {
			var item = list[i]
			if (item && item.primary) {
				return item.id || item.summary || ''
			}
		}
		if (list.length > 0) {
			return list[0].summary || list[0].id || ''
		}
		return ''
	}

	// https://developers.google.com/calendar/v3/errors
	function handleError(err, data) {
		if (data && data.error && data.error_description) {
			var errorMessage = '' + data.error + ' (' + data.error_description + ')'
			session.error(errorMessage)
		} else if (data && data.error && data.error.message && typeof data.error.code !== "undefined") {
			var errorMessage = '' + data.error.message + ' (' + data.error.code + ')'
			session.error(errorMessage)
		} else if (err) {
			session.error(err)
		}
	}
}
