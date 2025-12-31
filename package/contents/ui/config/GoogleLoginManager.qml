import QtQuick

import "../lib"
import "../lib/Pkce.js" as Pkce
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
		configBridge: session.configBridge
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

	property var calendarList: []
	property var calendarIdList: []
	property var tasklistList: []
	property var tasklistIdList: []

	property string localRedirectUri: "http://127.0.0.1:53682/"
	property string hostedRedirectUri: "https://alikestocode.github.io/plasma-applet-eventcalendar/"
	property string redirectMode: "local"
	function normalizedRedirectMode(mode) {
		return mode === "hosted" ? "hosted" : "local"
	}
	readonly property string redirectUri: normalizedRedirectMode(redirectMode) === "hosted"
		? hostedRedirectUri
		: localRedirectUri
	property string legacyClientId: "391436299960-k0s16nm589meovhoblpcquqgbbrena17.apps.googleusercontent.com"
	property string legacyClientSecret: "Gdr_7lKIQuGBD4Up3MOiw-7i"
	property string defaultClientId: "352447874752-sej1ldpd6piqgovtpog0dr91tb4sq5q3.apps.googleusercontent.com"
	property var configBridge: null
	function normalizedClientValue(value) {
		return value ? value.trim() : ""
	}
	property string effectiveClientId: ""
	property string effectiveClientSecret: ""
	property string pkceVerifier: ""
	property string pkceChallenge: ""
	property var pendingAuthContext: null

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
			session.refreshActiveAccount()
		}
	}

	Component.onCompleted: {
		if (!configBridge) {
			configBridge = ConfigUtils.findBridge(session)
		}
		session.accounts = accountsStore.accounts.slice(0)
		migrateDefaultClientIfNeeded()
		refreshActiveAccount()
		refreshClientCredentials()
		ensurePkce()
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
		if (activeAccount) {
			calendarList = activeAccount.calendarList || []
			calendarIdList = activeAccount.calendarIdList || []
			tasklistList = activeAccount.tasklistList || []
			tasklistIdList = activeAccount.tasklistIdList || []
		} else {
			calendarList = []
			calendarIdList = []
			tasklistList = []
			tasklistIdList = []
		}
	}

	function refreshClientCredentials() {
		migrateDefaultClientIfNeeded()
		var useDesktopClient = readConfig("useDesktopClient", false)
		var customId = normalizedClientValue(readConfig("customClientId", ""))
		var customSecret = normalizedClientValue(readConfig("customClientSecret", ""))
		var latestId = readConfig("latestClientId", "")
		var latestSecret = readConfig("latestClientSecret", "")
		if (customId || customSecret) {
			effectiveClientId = customId
			effectiveClientSecret = customSecret
		} else if (useDesktopClient) {
			effectiveClientId = defaultClientId
			effectiveClientSecret = ""
		} else {
			effectiveClientId = latestId
			effectiveClientSecret = latestSecret
		}
	}

	function migrateDefaultClientIfNeeded() {
		var customId = normalizedClientValue(readConfig("customClientId", ""))
		var customSecret = normalizedClientValue(readConfig("customClientSecret", ""))
		if (customId || customSecret) {
			return
		}
		var latestId = readConfig("latestClientId", "")
		if (!latestId) {
			writeConfig("latestClientId", defaultClientId)
		}
		var latestSecret = readConfig("latestClientSecret", "")
		if (latestId === legacyClientId && !latestSecret) {
			writeConfig("latestClientSecret", legacyClientSecret)
		}
	}

	function ensurePkce() {
		if (!pkceVerifier || !pkceChallenge) {
			resetPkce()
		}
	}

	function resetPkce() {
		pkceVerifier = Pkce.generateVerifier()
		pkceChallenge = Pkce.challengeFromVerifier(pkceVerifier)
	}
	function redirectUriForMode(mode) {
		return normalizedRedirectMode(mode) === "hosted" ? hostedRedirectUri : localRedirectUri
	}
	function buildAuthContext(modeOverride) {
		var mode = typeof modeOverride === "string" ? modeOverride : redirectMode
		return {
			clientId: effectiveClientId,
			clientSecret: effectiveClientSecret,
			redirectUri: redirectUriForMode(mode),
			pkceVerifier: pkceVerifier,
			pkceChallenge: pkceChallenge,
		}
	}
	function currentAuthContext() {
		return pendingAuthContext || buildAuthContext()
	}
	function prepareAuthorization() {
		refreshClientCredentials()
		var mode = normalizedRedirectMode(redirectMode)
		if (mode === "hosted" && !effectiveClientSecret) {
			writeConfig("googleRedirectMode", "local")
			error("Hosted mode requires a client secret. Switching to localhost.")
			mode = "local"
		}
		resetPkce()
		pendingAuthContext = buildAuthContext(mode)
	}
	function switchToLegacyClient() {
		writeConfig("latestClientId", legacyClientId)
		writeConfig("latestClientSecret", legacyClientSecret)
		refreshClientCredentials()
		prepareAuthorization()
	}
	function maybeUseLegacyForLocal() {
		var ctx = currentAuthContext()
		if (normalizedRedirectMode(redirectMode) !== "local") {
			return false
		}
		if (ctx.clientSecret) {
			return false
		}
		if (ctx.clientId !== defaultClientId) {
			return false
		}
		switchToLegacyClient()
		return true
	}
	function clearAuthorizationContext() {
		pendingAuthContext = null
	}
	function buildAuthorizationUrl(ctx) {
		var url = 'https://accounts.google.com/o/oauth2/v2/auth'
		url += '?scope=' + encodeURIComponent('https://www.googleapis.com/auth/calendar https://www.googleapis.com/auth/tasks')
		url += '&response_type=code'
		url += '&redirect_uri=' + encodeURIComponent(ctx.redirectUri)
		url += '&access_type=offline'
		url += '&prompt=consent'
		url += '&client_id=' + encodeURIComponent(ctx.clientId)
		if (ctx.pkceChallenge) {
			url += '&code_challenge=' + encodeURIComponent(ctx.pkceChallenge)
			url += '&code_challenge_method=S256'
		}
		return url
	}

	//--- Signals
	signal newAccessToken()
	signal sessionReset()
	signal error(string err)

	//---
	readonly property string authorizationCodeUrl: {
		return buildAuthorizationUrl(currentAuthContext())
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
		var ctx = currentAuthContext()
		var authCode = extractAuthorizationCode(args.authorizationCode)
		if (!authCode) {
			handleError('Invalid Google Authorization Code', null)
			return
		}
		var url = 'https://oauth2.googleapis.com/token'
		if (!ctx.pkceVerifier && !ctx.clientSecret) {
			handleError('Missing PKCE verifier. Start login from the widget and try again.', null)
			return
		}
		var payload = {
			client_id: ctx.clientId,
			code: authCode,
			grant_type: 'authorization_code',
			redirect_uri: ctx.redirectUri,
		}
		if (ctx.clientSecret) {
			payload.client_secret = ctx.clientSecret
		}
		if (ctx.pkceVerifier) {
			payload.code_verifier = ctx.pkceVerifier
		}
		Requests.post({
			url: url,
			data: payload,
		}, function(err, data, xhr) {
			logger.debug('/oauth2/v4/token Response', data)

			var parsed = null
			if (data) {
				try {
					parsed = JSON.parse(data)
				} catch (e) {
					parsed = null
				}
			}
			if (err) {
				handleError(err, parsed || data)
				return
			}
			if (!parsed) {
				handleError('Error parsing /oauth2/v4/token data as JSON', null)
				return
			}
			if (parsed && parsed.error) {
				var errorDesc = parsed.error_description || ""
				var missingSecret = parsed.error === "invalid_request" && errorDesc.indexOf("client_secret") !== -1
				if (missingSecret
					&& !ctx.clientSecret
					&& ctx.clientId === defaultClientId
					&& normalizedRedirectMode(redirectMode) === "local"
				) {
					switchToLegacyClient()
					error("Google requires a client secret for the built-in client. Switching to a fallback login. Please complete the login again.")
					Qt.openUrlExternally(authorizationCodeUrl)
					return
				}
				handleError(err, parsed)
				return
			}

			// Ready
			updateAccessToken(parsed, args.accountId)
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
		clearAuthorizationContext()
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
				logger.log('updateTasklistList error', err, data)
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
			clearAuthorizationContext()
		} else if (data && data.error && data.error.message && typeof data.error.code !== "undefined") {
			var errorMessage = '' + data.error.message + ' (' + data.error.code + ')'
			session.error(errorMessage)
			clearAuthorizationContext()
		} else if (err) {
			session.error(err)
			clearAuthorizationContext()
		}
	}
}
