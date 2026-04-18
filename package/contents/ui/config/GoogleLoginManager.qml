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
		if (activeAccount.sessionClientId && activeAccount.sessionClientId != effectiveClientId) {
			return true
		}
		if (activeAccount.sessionUsesPkce !== undefined
			&& activeAccount.sessionUsesPkce !== (!effectiveClientSecret)
		) {
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
	property string defaultClientId: "352447874752-sej1ldpd6piqgovtpog0dr91tb4sq5q3.apps.googleusercontent.com"
	property var configBridge: null
	function normalizedClientValue(value) {
		return value ? value.trim() : ""
	}
	property string effectiveClientId: ""
	property string effectiveClientSecret: ""
	property string pkceVerifier: ""
	property string pkceChallenge: ""
	property string authState: ""
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
		var latestId = normalizedClientValue(readConfig("latestClientId", ""))
		var latestSecret = normalizedClientValue(readConfig("latestClientSecret", ""))
		if (customId) {
			effectiveClientId = customId
			effectiveClientSecret = customSecret
		} else if (!useDesktopClient && latestId) {
			effectiveClientId = latestId
			effectiveClientSecret = latestSecret
		} else {
			effectiveClientId = defaultClientId
			effectiveClientSecret = ""
		}
	}

	function migrateDefaultClientIfNeeded() {
		var customId = normalizedClientValue(readConfig("customClientId", ""))
		if (customId) {
			return
		}
		var latestId = normalizedClientValue(readConfig("latestClientId", ""))
		var latestSecret = normalizedClientValue(readConfig("latestClientSecret", ""))
		if (!latestId) {
			writeConfig("latestClientId", defaultClientId)
			latestId = defaultClientId
		}
		if (latestSecret) {
			if (readConfig("useDesktopClient", false) !== false) {
				writeConfig("useDesktopClient", false)
			}
		} else if (readConfig("useDesktopClient", false) !== true) {
			writeConfig("useDesktopClient", true)
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
	function generateAuthState() {
		return Pkce.generateOpaqueToken(32)
	}
	function ensureAuthState() {
		if (!authState) {
			authState = generateAuthState()
		}
	}
	function resetAuthState() {
		authState = generateAuthState()
	}
	function redirectUriForMode(mode) {
		return normalizedRedirectMode(mode) === "hosted" ? hostedRedirectUri : localRedirectUri
	}
	function buildAuthContext(modeOverride) {
		var mode = typeof modeOverride === "string" ? modeOverride : redirectMode
		var usePkce = !effectiveClientSecret
		return {
			clientId: effectiveClientId,
			clientSecret: effectiveClientSecret,
			redirectUri: redirectUriForMode(mode),
			pkceVerifier: usePkce ? pkceVerifier : "",
			pkceChallenge: usePkce ? pkceChallenge : "",
			state: authState,
		}
	}
	function currentAuthContext() {
		return pendingAuthContext || buildAuthContext()
	}
	function prepareAuthorization() {
		refreshClientCredentials()
		var mode = normalizedRedirectMode(redirectMode)
		if (!effectiveClientSecret) {
			resetPkce()
		} else {
			pkceVerifier = ""
			pkceChallenge = ""
		}
		resetAuthState()
		pendingAuthContext = buildAuthContext(mode)
	}
	function maybeUseLegacyForLocal() {
		return false
	}
	function clearAuthorizationContext() {
		authState = ""
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
		if (ctx.state) {
			url += '&state=' + encodeURIComponent(ctx.state)
		}
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
			accountsStore.updateAccount(activeAccountId, {
				calendarIdList: list,
				calendarSelectionInitialized: true,
			})
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

	function describeAuthError(ctx, data, fallbackErr) {
		var errorDescription = data && data.error_description
			? String(data.error_description)
			: ""
		if (data && data.error === "invalid_request"
			&& errorDescription.toLowerCase().indexOf("client_secret is missing") !== -1
		) {
			if (!ctx.clientSecret && ctx.clientId === defaultClientId) {
				return "Google rejected the built-in login because this client now requires a client secret. Add your own Google OAuth client ID and client secret, or switch back to a previously stored secret-based client."
			}
			return errorDescription
		}
		if (errorDescription) {
			return errorDescription
		}
		if (data && data.error && data.error.message) {
			return String(data.error.message)
		}
		if (data && data.error) {
			return String(data.error)
		}
		return fallbackErr || "Google authentication failed."
	}

	function fetchAccessToken(args, callback) {
		var ctx = currentAuthContext()
		var authCode = extractAuthorizationCode(args.authorizationCode)
		var existingAccount = args.accountId ? accountsStore.getAccount(args.accountId) : null
		if (!authCode) {
			handleError('Invalid Google Authorization Code', null)
			if (typeof callback === "function") {
				callback('Invalid Google Authorization Code')
			}
			return
		}
		var url = 'https://oauth2.googleapis.com/token'
		if (!ctx.pkceVerifier && !ctx.clientSecret) {
			handleError('Missing PKCE verifier. Start login from the widget and try again.', null)
			if (typeof callback === "function") {
				callback('Missing PKCE verifier. Start login from the widget and try again.')
			}
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
				var requestError = describeAuthError(ctx, parsed, err)
				handleError(requestError, null)
				if (typeof callback === "function") {
					callback(requestError)
				}
				return
			}
			if (!parsed) {
				handleError('Error parsing /oauth2/v4/token data as JSON', null)
				if (typeof callback === "function") {
					callback('Error parsing token response.')
				}
				return
			}
			if (parsed && parsed.error) {
				var parsedError = describeAuthError(ctx, parsed, err)
				handleError(parsedError, null)
				if (typeof callback === "function") {
					callback(parsedError)
				}
				return
			}
			if (!parsed.refresh_token && !(existingAccount && existingAccount.refreshToken)) {
				var refreshTokenError = "Google login completed, but no refresh token was returned. Revoke the app's Google access and login again."
				handleError(refreshTokenError, null)
				if (typeof callback === "function") {
					callback(refreshTokenError)
				}
				return
			}

			// Ready
			updateAccessToken(parsed, args.accountId)
			if (typeof callback === "function") {
				callback(null, parsed)
			}
		})
	}

	function updateAccessToken(data, accountId) {
		var account = accountId ? accountsStore.getAccount(accountId) : null
		var targetId = accountId
		if (!account) {
			var created = accountsStore.addAccount({
				label: '',
				skipDefaultCalendarSelection: true,
			})
			targetId = created.id
		}
		accountsStore.updateAccount(targetId, {
			sessionClientId: effectiveClientId,
			sessionUsesPkce: !effectiveClientSecret,
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
			if (!activeAccount.calendarSelectionInitialized
				&& (!activeAccount.calendarIdList || !activeAccount.calendarIdList.length)
				&& accountsStore.defaultCalendarIdList
			) {
				var defaultList = accountsStore.defaultCalendarIdList(data.items)
				if (defaultList.length) {
					patch.calendarIdList = defaultList
					patch.calendarSelectionInitialized = true
				}
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
