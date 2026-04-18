import QtQuick 2.0

import "../lib"
import "../lib/Pkce.js" as Pkce
import "../lib/Requests.js" as Requests

Item {
	id: session

	ExecUtil { id: executable }

	property int callbackListenPort: 8001
	property string authState: ""
	property string pkceVerifier: ""
	property string pkceChallenge: ""
	property string defaultClientId: "352447874752-sej1ldpd6piqgovtpog0dr91tb4sq5q3.apps.googleusercontent.com"
	property string secretStorePath: plasmoid.file("", "scripts/secret_store.py")

	Logger {
		id: logger
		showDebug: plasmoid.configuration.debugging
	}

	Component.onCompleted: {
		if (plasmoid.configuration.latestClientId !== defaultClientId) {
			plasmoid.configuration.latestClientId = defaultClientId
		}
		if (plasmoid.configuration.latestClientSecret) {
			plasmoid.configuration.latestClientSecret = ""
		}
		if (plasmoid.configuration.sessionClientSecret) {
			plasmoid.configuration.sessionClientSecret = ""
		}
		if (plasmoid.configuration.refreshToken) {
			storeRefreshToken(plasmoid.configuration.refreshToken)
			plasmoid.configuration.refreshToken = ""
		}
		ensurePkce()
	}

	readonly property bool isLoggedIn: !!plasmoid.configuration.accessToken
	readonly property bool needsRelog: {
		if (plasmoid.configuration.accessToken && plasmoid.configuration.sessionClientId !== defaultClientId) {
			return true
		}
		if (!plasmoid.configuration.accessToken && plasmoid.configuration.access_token) {
			return true
		}
		return false
	}

	property var m_calendarList: ConfigSerializedString {
		id: m_calendarList
		configKey: "calendarList"
		defaultValue: []
	}
	property alias calendarList: m_calendarList.value

	property var m_calendarIdList: ConfigSerializedString {
		id: m_calendarIdList
		configKey: "calendarIdList"
		defaultValue: []

		function serialize() {
			plasmoid.configuration[configKey] = value.join(",")
		}
		function deserialize() {
			value = configValue.split(",")
		}
	}
	property alias calendarIdList: m_calendarIdList.value

	property var m_tasklistList: ConfigSerializedString {
		id: m_tasklistList
		configKey: "tasklistList"
		defaultValue: []
	}
	property alias tasklistList: m_tasklistList.value

	property var m_tasklistIdList: ConfigSerializedString {
		id: m_tasklistIdList
		configKey: "tasklistIdList"
		defaultValue: []

		function serialize() {
			plasmoid.configuration[configKey] = value.join(",")
		}
		function deserialize() {
			value = configValue.split(",")
		}
	}
	property alias tasklistIdList: m_tasklistIdList.value

	signal newAccessToken()
	signal sessionReset()
	signal error(string err)

	function redirectUri() {
		return "http://127.0.0.1:" + callbackListenPort.toString() + "/"
	}

	function generateAuthState() {
		return String(Qt.createUuid()).replace(/[{}\-]/g, "")
	}

	function ensurePkce() {
		if (!pkceVerifier || !pkceChallenge) {
			pkceVerifier = Pkce.generateVerifier()
			pkceChallenge = Pkce.challengeFromVerifier(pkceVerifier)
		}
	}

	readonly property string authorizationCodeUrl: {
		ensurePkce()
		var url = "https://accounts.google.com/o/oauth2/v2/auth"
		url += "?scope=" + encodeURIComponent("https://www.googleapis.com/auth/calendar https://www.googleapis.com/auth/tasks")
		url += "&response_type=code"
		url += "&redirect_uri=" + encodeURIComponent(redirectUri())
		url += "&access_type=offline"
		url += "&prompt=consent"
		url += "&client_id=" + encodeURIComponent(defaultClientId)
		if (authState) {
			url += "&state=" + encodeURIComponent(authState)
		}
		if (pkceChallenge) {
			url += "&code_challenge=" + encodeURIComponent(pkceChallenge)
			url += "&code_challenge_method=S256"
		}
		return url
	}

	function generateTempFilePath(prefix) {
		var timePart = Date.now().toString(36)
		var randPart = Math.floor(Math.random() * 1000000).toString(36)
		return "/tmp/" + prefix + "-" + timePart + "-" + randPart + ".json"
	}

	function localFileUrl(path) {
		return path.indexOf("file://") === 0 ? path : "file://" + path
	}

	function delay(delayTime, callback) {
		var timer = Qt.createQmlObject("import QtQuick 2.0; Timer {}", session)
		timer.interval = delayTime
		timer.repeat = false
		timer.triggered.connect(function() {
			timer.destroy()
			callback()
		})
		timer.start()
	}

	function waitForReadyFile(readyFile, callback, attemptsLeft) {
		if (attemptsLeft === undefined) {
			attemptsLeft = 50
		}
		Requests.getFile(localFileUrl(readyFile), function(err, data) {
			var payload = null
			if (!err && data) {
				try {
					payload = JSON.parse(data)
				} catch (e) {
					payload = null
				}
			}
			if (payload && payload.port && payload.token) {
				callback(null, payload)
				return
			}
			if (attemptsLeft <= 0) {
				callback("Timed out waiting for secret storage helper.")
				return
			}
			delay(100, function() {
				waitForReadyFile(readyFile, callback, attemptsLeft - 1)
			})
		})
	}

	function storeRefreshToken(refreshToken, callback) {
		if (!refreshToken) {
			clearRefreshToken(callback)
			return
		}
		var readyFile = generateTempFilePath("eventcalendar-secret-store")
		executable.execArgv([
			"python3",
			secretStorePath,
			"store-once",
			"--scope",
			"google-session",
			"--key",
			"refresh_token",
			"--ready-file",
			readyFile,
		], function(cmd, exitCode, exitStatus, stdout, stderr) {
			if (exitCode !== 0 && typeof callback === "function") {
				callback((stderr || stdout || "").trim() || "Failed to store refresh token.")
			}
		})
		waitForReadyFile(readyFile, function(err, payload) {
			if (err) {
				if (typeof callback === "function") {
					callback(err)
				}
				return
			}
			Requests.postJSON({
				url: "http://127.0.0.1:" + payload.port + "/store",
				headers: {
					"Authorization": "Bearer " + payload.token,
				},
				data: {
					value: refreshToken,
				},
			}, function(postErr, data, xhr) {
				if (typeof callback === "function") {
					if (postErr || !data || data.ok !== true) {
						callback(postErr || (data && data.error) || "Failed to store refresh token.")
					} else {
						callback(null)
					}
				}
			})
		})
	}

	function clearRefreshToken(callback) {
		executable.execArgv([
			"python3",
			secretStorePath,
			"clear",
			"--scope",
			"google-session",
			"--key",
			"refresh_token",
		], function(cmd, exitCode, exitStatus, stdout, stderr) {
			if (typeof callback === "function") {
				if (exitCode === 0) {
					callback(null)
				} else {
					callback((stderr || stdout || "").trim() || "Failed to clear refresh token.")
				}
			}
		})
	}

	function fetchAccessToken() {
		ensurePkce()
		authState = generateAuthState()

		var cmd = [
			"python3",
			plasmoid.file("", "scripts/google_redirect.py"),
			"--listen_port",
			callbackListenPort.toString(),
			"--state",
			authState,
		]

		Qt.openUrlExternally(authorizationCodeUrl)

		executable.execArgv(cmd, function(cmd, exitCode, exitStatus, stdout, stderr) {
			if (exitCode) {
				logger.log("fetchAccessToken.stderr", stderr)
				logger.log("fetchAccessToken.stdout", stdout)
				if ((stderr || "").indexOf("State mismatch") !== -1) {
					handleError("Google login failed because the browser returned an unexpected state token. Please retry the login.", null)
				} else {
					handleError(stderr || "Google login failed.", null)
				}
				return
			}

			var payload = null
			try {
				payload = JSON.parse(stdout)
			} catch (e) {
				logger.log("fetchAccessToken.e", e)
				handleError("Error parsing JSON", null)
				return
			}
			if (!payload || !payload.authorization_code) {
				handleError("Authorization code missing from callback.", null)
				return
			}

			exchangeAuthorizationCode(payload.authorization_code)
		})
	}

	function exchangeAuthorizationCode(authorizationCode) {
		Requests.post({
			url: "https://oauth2.googleapis.com/token",
			data: {
				client_id: defaultClientId,
				code: authorizationCode,
				grant_type: "authorization_code",
				redirect_uri: redirectUri(),
				code_verifier: pkceVerifier,
			},
		}, function(err, data, xhr) {
			var parsed = null
			if (data) {
				try {
					parsed = JSON.parse(data)
				} catch (e) {
					parsed = null
				}
			}
			if (err || !parsed) {
				handleError(err || "Error parsing token response.", parsed)
				return
			}
			if (parsed.error) {
				handleError(err, parsed)
				return
			}
			updateAccessToken(parsed)
		})
	}

	function updateAccessToken(data) {
		authState = ""
		plasmoid.configuration.latestClientId = defaultClientId
		plasmoid.configuration.latestClientSecret = ""
		plasmoid.configuration.sessionClientId = defaultClientId
		plasmoid.configuration.sessionClientSecret = ""
		plasmoid.configuration.accessToken = data.access_token
		plasmoid.configuration.accessTokenType = data.token_type
		plasmoid.configuration.accessTokenExpiresAt = Date.now() + data.expires_in * 1000
		plasmoid.configuration.refreshToken = ""
		if (data.refresh_token) {
			storeRefreshToken(data.refresh_token)
		}
		newAccessToken()
	}

	onNewAccessToken: updateData()

	function updateData() {
		updateCalendarList()
		updateTasklistList()
	}

	function updateCalendarList() {
		logger.debug("updateCalendarList")
		logger.debug("accessToken", plasmoid.configuration.accessToken)
		fetchGCalCalendars({
			accessToken: plasmoid.configuration.accessToken,
		}, function(err, data, xhr) {
			if (err || data.error) {
				handleError(err, data)
				return
			}
			m_calendarList.value = data.items
		})
	}

	function fetchGCalCalendars(args, callback) {
		var url = "https://www.googleapis.com/calendar/v3/users/me/calendarList"
		Requests.getJSON({
			url: url,
			headers: {
				"Authorization": "Bearer " + args.accessToken,
			}
		}, function(err, data, xhr) {
			if (!err && data && data.error) {
				return callback("fetchGCalCalendars error", data, xhr)
			}
			logger.debugJSON("fetchGCalCalendars.response.data", data)
			callback(err, data, xhr)
		})
	}

	function updateTasklistList() {
		logger.debug("updateTasklistList")
		logger.debug("accessToken", plasmoid.configuration.accessToken)
		fetchGoogleTasklistList({
			accessToken: plasmoid.configuration.accessToken,
		}, function(err, data, xhr) {
			if (err || data.error) {
				handleError(err, data)
				return
			}
			m_tasklistList.value = data.items
		})
	}

	function fetchGoogleTasklistList(args, callback) {
		var url = "https://www.googleapis.com/tasks/v1/users/@me/lists"
		Requests.getJSON({
			url: url,
			headers: {
				"Authorization": "Bearer " + args.accessToken,
			}
		}, function(err, data, xhr) {
			console.log("fetchGoogleTasklistList.response", err, data, xhr && xhr.status)
			if (!err && data && data.error) {
				return callback("fetchGoogleTasklistList error", data, xhr)
			}
			logger.debugJSON("fetchGoogleTasklistList.response.data", data)
			callback(err, data, xhr)
		})
	}

	function logout() {
		plasmoid.configuration.sessionClientId = ""
		plasmoid.configuration.sessionClientSecret = ""
		plasmoid.configuration.accessToken = ""
		plasmoid.configuration.accessTokenType = ""
		plasmoid.configuration.accessTokenExpiresAt = 0
		plasmoid.configuration.refreshToken = ""
		clearRefreshToken()

		plasmoid.configuration.agendaNewEventLastCalendarId = ""
		calendarList = []
		calendarIdList = []
		tasklistList = []
		tasklistIdList = []
		sessionReset()
	}

	function handleError(err, data) {
		if (data && data.error && data.error_description) {
			var errorMessage = "" + data.error + " (" + data.error_description + ")"
			session.error(errorMessage)
		} else if (data && data.error && data.error.message && typeof data.error.code !== "undefined") {
			var apiErrorMessage = "" + data.error.message + " (" + data.error.code + ")"
			session.error(apiErrorMessage)
		} else if (err) {
			session.error(err)
		}
	}
}
