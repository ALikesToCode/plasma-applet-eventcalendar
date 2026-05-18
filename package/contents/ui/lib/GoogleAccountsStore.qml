import QtQuick

import "ConfigUtils.js" as ConfigUtils
import "GoogleAccountState.js" as GoogleAccountState
import "Requests.js" as Requests
import "SafeConfig.js" as SafeConfig

Item {
	id: store
	visible: false

	property string accountsKey: "googleAccounts"
	property string activeAccountKey: "googleActiveAccountId"

	property var configBridge: null
	property bool debugEnabled: false
	property string secretStorePath: {
		var resolved = String(Qt.resolvedUrl("../../scripts/secret_store.py"))
		return resolved.indexOf("file://") === 0 ? resolved.slice(7) : resolved
	}

	property var accountsConfigValue: ""
	property string activeAccountId: ""

	property var accounts: []

	signal accountUpdated(string accountId)

	Logger {
		id: logger
		name: "eventcalendar"
		showDebug: store.debugEnabled
	}

	ExecUtil {
		id: secretExec
	}

	Component.onCompleted: {
		if (!configBridge) {
			configBridge = ConfigUtils.findBridge(store)
		}
		syncFromConfig()
		loadAccounts()
		migrateLegacyAccountIfNeeded()
	}

	Connections {
		target: !configBridge && typeof plasmoid !== "undefined" && plasmoid.configuration
			? plasmoid.configuration
			: null
		function onGoogleAccountsChanged() {
			store.syncFromConfig()
		}
		function onGoogleActiveAccountIdChanged() {
			store.syncFromConfig()
		}
		function onDebuggingChanged() {
			store.syncFromConfig()
		}
	}

	onConfigBridgeChanged: {
		syncFromConfig()
		loadAccounts()
	}

	onAccountsConfigValueChanged: loadAccounts()
	onActiveAccountIdChanged: {
		if (activeAccountId && !getAccount(activeAccountId)) {
			ensureActiveAccount()
		}
	}

	function syncFromConfig() {
		debugEnabled = readConfig("debugging", false)
		var nextAccountsValue = readConfig(accountsKey, "")
		if (accountsConfigValue !== nextAccountsValue) {
			accountsConfigValue = nextAccountsValue
		}
		var nextActiveId = readConfig(activeAccountKey, "")
		if (activeAccountId !== nextActiveId) {
			activeAccountId = nextActiveId
		}
	}

	function loadAccounts() {
		var parsed = normalizeAccounts(parseAccounts(accountsConfigValue))
		var needsSecretMigration = accountsNeedSecretMigration(parsed)
		GoogleAccountState.preserveRuntimeCredentialsForAccounts(parsed, accounts)
		if (hasSameAccountIds(accounts, parsed)) {
			for (var i = 0; i < parsed.length; i++) {
				accounts[i] = parsed[i]
				accountUpdated(parsed[i].id)
			}
		} else {
			accounts = parsed
		}
		if (needsSecretMigration) {
			migrateSecretsToSecretStore(parsed, function(err) {
				if (err) {
					logger.log('Could not migrate Google account secrets:', err)
					return
				}
				serialize()
			})
		}
		loadStoredSecrets()
		ensureActiveAccount()
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

	function hasSameAccountIds(listA, listB) {
		if (listA.length !== listB.length) {
			return false
		}
		for (var i = 0; i < listA.length; i++) {
			if (listA[i].id !== listB[i].id) {
				return false
			}
		}
		return true
	}

	function parseAccounts(value) {
		if (!value) {
			return []
		}
		if (Array.isArray(value)) {
			return value
		}
		if (typeof value === "object") {
			return []
		}
		try {
			var parsed = SafeConfig.parseBase64Json(value, [])
			return Array.isArray(parsed) ? parsed : []
		} catch (e) {
			return []
		}
	}

	function normalizeAccounts(list) {
		var normalized = []
		for (var i = 0; i < list.length; i++) {
			var account = normalizeAccount(list[i])
			if (account) {
				normalized.push(account)
			}
		}
		return normalized
	}

	function normalizeAccount(account) {
		if (!account) {
			return null
		}
		var normalized = {}
		normalized.id = account.id || generateId()
		normalized.label = account.label || ""
		normalized.sessionClientId = account.sessionClientId || ""
		normalized.sessionClientSecret = account.sessionClientSecret || ""
		normalized.sessionUsesPkce = account.sessionUsesPkce !== undefined
			? account.sessionUsesPkce === true
			: !normalized.sessionClientSecret
		normalized.accessToken = account.accessToken || ""
		normalized.accessTokenType = account.accessTokenType || ""
		normalized.accessTokenExpiresAt = account.accessTokenExpiresAt || 0
		normalized.refreshToken = account.refreshToken || ""
		normalized.calendarList = Array.isArray(account.calendarList) ? account.calendarList : []
		normalized.calendarIdList = ensureStringArray(account.calendarIdList)
		normalized.calendarSelectionInitialized = account.calendarSelectionInitialized === true
		normalized.tasklistList = Array.isArray(account.tasklistList) ? account.tasklistList : []
		normalized.tasklistIdList = ensureStringArray(account.tasklistIdList)
		return normalized
	}

	function ensureStringArray(value) {
		if (Array.isArray(value)) {
			return value.filter(function(item){ return !!item })
		}
		if (typeof value === "string") {
			return value.split(',').filter(function(item){ return !!item })
		}
		return []
	}

	function defaultCalendarIdList(calendarList) {
		if (!Array.isArray(calendarList)) {
			return []
		}
		for (var i = 0; i < calendarList.length; i++) {
			var calendar = calendarList[i]
			if (calendar && calendar.primary) {
				return ["primary"]
			}
		}
		for (var j = 0; j < calendarList.length; j++) {
			var fallbackCalendar = calendarList[j]
			if (fallbackCalendar && fallbackCalendar.id) {
				return [fallbackCalendar.id]
			}
		}
		return []
	}

	function ensureCalendarSelection(accountId, calendarListOverride) {
		var account = getAccount(accountId)
		if (!account) {
			return []
		}
		var currentList = ensureStringArray(account.calendarIdList)
		if (account.calendarSelectionInitialized) {
			return currentList
		}
		if (currentList.length) {
			updateAccount(accountId, {
				calendarSelectionInitialized: true,
			})
			return currentList
		}
		var sourceList = Array.isArray(calendarListOverride) ? calendarListOverride : account.calendarList
		var defaultList = defaultCalendarIdList(sourceList)
		if (defaultList.length) {
			updateAccount(accountId, {
				calendarIdList: defaultList,
				calendarSelectionInitialized: true,
			})
			return defaultList
		}
		return []
	}

	function serializeAccount(account) {
		return GoogleAccountState.serializeAccountForConfig(account)
	}

	function serialize() {
		var safeAccounts = (accounts || []).map(serializeAccount)
		var payload = SafeConfig.serializeBase64Json(safeAccounts)
		if (configBridge) {
			accountsConfigValue = payload
		}
		writeConfig(accountsKey, payload)
	}

	function generateId() {
		var timePart = Date.now().toString(36)
		var randPart = Math.floor(Math.random() * 1000000).toString(36)
		return "acc_" + timePart + "_" + randPart
	}

	function getAccountIndex(accountId) {
		for (var i = 0; i < accounts.length; i++) {
			if (accounts[i].id === accountId) {
				return i
			}
		}
		return -1
	}

	function getAccount(accountId) {
		var index = getAccountIndex(accountId)
		if (index >= 0) {
			return accounts[index]
		}
		return null
	}

	function addAccount(account) {
		var normalized = normalizeAccount(account || {})
		var skipDefaultSelection = account && account.skipDefaultCalendarSelection === true
		var skipSecretStorage = account && account.skipSecretStorage === true
		if (!normalized.calendarIdList.length && !skipDefaultSelection) {
			normalized.calendarIdList = ["primary"]
			normalized.calendarSelectionInitialized = true
		}
		var nextAccounts = accounts.slice(0)
		nextAccounts.push(normalized)
		accounts = nextAccounts
		if (!skipSecretStorage && normalized.refreshToken) {
			storeRefreshToken(normalized.id, normalized.refreshToken)
		}
		if (!skipSecretStorage && normalized.sessionClientSecret) {
			storeSessionClientSecret(normalized.id, normalized.sessionClientSecret)
		}
		serialize()
		if (!activeAccountId) {
			setActiveAccountId(normalized.id)
		}
		return normalized
	}

	function updateAccount(accountId, patch) {
		var index = getAccountIndex(accountId)
		if (index < 0) {
			return
		}
		var current = accounts[index]
		var next = {}
		for (var key in current) {
			next[key] = current[key]
		}
		for (var patchKey in patch) {
			next[patchKey] = patch[patchKey]
		}
		accounts[index] = normalizeAccount(next)
		if (patch.refreshToken !== undefined) {
			logger.debugJSON("updateAccount.refreshToken", {
				accountId: accountId,
				action: patch.refreshToken ? "store" : "clear",
				length: (patch.refreshToken || "").length,
			})
			storeRefreshToken(accountId, patch.refreshToken || "")
		}
		if (patch.sessionClientSecret !== undefined) {
			logger.debugJSON("updateAccount.sessionClientSecret", {
				accountId: accountId,
				action: patch.sessionClientSecret ? "store" : "clear",
				length: (patch.sessionClientSecret || "").length,
			})
			storeSessionClientSecret(accountId, patch.sessionClientSecret || "")
		}
		serialize()
		accountUpdated(accountId)
	}

	function removeAccount(accountId) {
		var index = getAccountIndex(accountId)
		if (index < 0) {
			return
		}
		var nextAccounts = accounts.slice(0)
		nextAccounts.splice(index, 1)
		accounts = nextAccounts
		clearRefreshToken(accountId)
		clearSessionClientSecret(accountId)
		serialize()
		if (activeAccountId === accountId) {
			setActiveAccountId(accounts.length ? accounts[0].id : "")
		}
	}

	function inspectStoredRefreshTokens(callback) {
		var statuses = []
		function inspectIndex(index) {
			if (index >= accounts.length) {
				if (typeof callback === "function") {
					callback(statuses)
				}
				return
			}
			var account = accounts[index]
			if (!account || !account.id) {
				inspectIndex(index + 1)
				return
			}
			loadRefreshToken(account.id, function(err, refreshToken) {
				statuses.push({
					accountId: account.id,
					hasStoredRefreshToken: !err && !!refreshToken,
					isInitialized: !!(account.label
						|| (account.calendarList && account.calendarList.length)
						|| (account.tasklistList && account.tasklistList.length)),
				})
				inspectIndex(index + 1)
			})
		}
		inspectIndex(0)
	}

	function findReusableAccount(callback) {
		inspectStoredRefreshTokens(function(statuses) {
			var reusableId = ""
			var missingIds = []
			var incompleteIds = []
			for (var i = statuses.length - 1; i >= 0; i--) {
				var status = statuses[i]
				if (!status.hasStoredRefreshToken) {
					missingIds.unshift(status.accountId)
					reusableId = status.accountId
					break
				}
				if (!status.isInitialized) {
					incompleteIds.unshift(status.accountId)
					if (!reusableId) {
						reusableId = status.accountId
					}
				}
			}
			logger.debugJSON("findReusableAccount.result", {
				reusableId: reusableId,
				missingIds: missingIds,
				incompleteIds: incompleteIds,
			})
			if (typeof callback === "function") {
				callback(reusableId)
			}
		})
	}

	function pruneDeadAccounts(exceptAccountId, callback) {
		inspectStoredRefreshTokens(function(statuses) {
			var removedIds = []
			for (var i = 0; i < statuses.length; i++) {
				var status = statuses[i]
				if (status.accountId === exceptAccountId || status.hasStoredRefreshToken) {
					continue
				}
				removedIds.push(status.accountId)
			}
			for (var j = 0; j < removedIds.length; j++) {
				removeAccount(removedIds[j])
			}
			logger.debugJSON("pruneDeadAccounts.result", {
				exceptAccountId: exceptAccountId || "",
				removedIds: removedIds,
			})
			if (typeof callback === "function") {
				callback(removedIds)
			}
		})
	}

	function pruneReusableAccounts(exceptAccountId, callback) {
		inspectStoredRefreshTokens(function(statuses) {
			var removedIds = []
			for (var i = 0; i < statuses.length; i++) {
				var status = statuses[i]
				if (status.accountId === exceptAccountId) {
					continue
				}
				if (!status.hasStoredRefreshToken || !status.isInitialized) {
					removedIds.push(status.accountId)
				}
			}
			for (var j = 0; j < removedIds.length; j++) {
				removeAccount(removedIds[j])
			}
			logger.debugJSON("pruneReusableAccounts.result", {
				exceptAccountId: exceptAccountId || "",
				removedIds: removedIds,
			})
			if (typeof callback === "function") {
				callback(removedIds)
			}
		})
	}

	function setActiveAccountId(accountId) {
		if (configBridge) {
			activeAccountId = accountId
		}
		writeConfig(activeAccountKey, accountId)
	}

	function ensureActiveAccount() {
		if (accounts.length === 0) {
			return
		}
		if (!activeAccountId || !getAccount(activeAccountId)) {
			setActiveAccountId(accounts[0].id)
		}
	}

	function decodeLegacyBase64Json(value) {
		if (!value) {
			return []
		}
		try {
			var parsed = SafeConfig.parseBase64Json(value, [])
			return Array.isArray(parsed) ? parsed : []
		} catch (e) {
			return []
		}
	}

	function parseLegacyList(value) {
		if (!value) {
			return []
		}
		return value.split(',').filter(function(item){ return !!item })
	}

	function deriveLabelFromCalendars(list) {
		if (!Array.isArray(list)) {
			return ""
		}
		for (var i = 0; i < list.length; i++) {
			var item = list[i]
			if (item && item.primary) {
				return item.id || item.summary || ""
			}
		}
		if (list.length > 0) {
			return list[0].summary || list[0].id || ""
		}
		return ""
	}

	function accountsNeedSecretMigration(list) {
		for (var i = 0; i < list.length; i++) {
			var account = list[i]
			if (account && (account.refreshToken || account.accessToken || account.sessionClientSecret)) {
				return true
			}
		}
		return false
	}

	function migrateSecretsToSecretStore(list, callback) {
		var pending = 0
		var firstError = ""
		function migrated(err) {
			if (err && !firstError) {
				firstError = err
			}
			pending -= 1
			if (pending === 0 && typeof callback === "function") {
				callback(firstError || null)
			}
		}
		function storeMigrationSecret(storeFunction, accountId, value) {
			pending += 1
			storeFunction(accountId, value, migrated)
		}
		for (var i = 0; i < list.length; i++) {
			var account = list[i]
			if (account && account.refreshToken) {
				storeMigrationSecret(storeRefreshToken, account.id, account.refreshToken)
			}
			if (account && account.sessionClientSecret) {
				storeMigrationSecret(storeSessionClientSecret, account.id, account.sessionClientSecret)
			}
		}
		if (pending === 0 && typeof callback === "function") {
			callback(null)
		}
	}

	function localFileUrl(path) {
		return path.indexOf("file://") === 0 ? path : "file://" + path
	}

	function generateTempFilePath(prefix) {
		var timePart = Date.now().toString(36)
		var randPart = Math.floor(Math.random() * 1000000).toString(36)
		return "/tmp/" + prefix + "-" + timePart + "-" + randPart + ".json"
	}

	function delay(delayTime, callback) {
		var timer = Qt.createQmlObject("import QtQuick; Timer {}", store)
		timer.interval = delayTime
		timer.repeat = false
		timer.triggered.connect(function() {
			timer.destroy()
			callback()
		})
		timer.start()
	}

	function waitForReadyFile(readyFile, callback, attemptsLeft) {
		var timeoutSeconds = attemptsLeft !== undefined ? attemptsLeft : 5
		secretExec.execArgv([
			"python3",
			secretStorePath,
			"wait-ready",
			"--ready-file",
			readyFile,
			"--timeout",
			String(timeoutSeconds),
		], function(cmd, exitCode, exitStatus, stdout, stderr) {
			var payload = null
			var trimmed = (stdout || "").trim()
			if (trimmed) {
				try {
					payload = JSON.parse(trimmed)
				} catch (e) {
					payload = null
				}
			}
			if (exitCode === 0 && payload && payload.port && payload.token) {
				callback(null, payload)
				return
			}
			callback((stderr || stdout || "").trim() || "Timed out waiting for secret storage helper.")
		})
	}

	function updateAccountSecret(accountId, patch) {
		var index = getAccountIndex(accountId)
		if (index < 0) {
			return
		}
		var next = normalizeAccount(accounts[index])
		for (var key in patch) {
			next[key] = patch[key]
		}
		accounts[index] = normalizeAccount(next)
		accountUpdated(accountId)
	}

	function storeAccountSecret(accountId, key, value, callback) {
		var finished = false
		function finish(err) {
			if (finished) {
				return
			}
			finished = true
			if (typeof callback === "function") {
				callback(err || null)
			}
		}
		if (!accountId) {
			finish("Missing account id.")
			return
		}
		if (!value) {
			clearAccountSecret(accountId, key, callback)
			return
		}
		var readyFile = generateTempFilePath("eventcalendar-secret-store")
		logger.debugJSON("storeAccountSecret.start", {
			accountId: accountId,
			key: key,
			length: value.length,
			readyFile: readyFile,
		})
		secretExec.execArgv([
			"python3",
			secretStorePath,
			"store-once",
			"--scope",
			"google-account",
			"--key",
			key,
			"--account-id",
			accountId,
			"--ready-file",
			readyFile,
		], function(cmd, exitCode, exitStatus, stdout, stderr) {
			logger.debugJSON("storeAccountSecret.helperExit", {
				accountId: accountId,
				key: key,
				exitCode: exitCode,
				exitStatus: exitStatus,
				stdout: (stdout || "").trim(),
				stderr: (stderr || "").trim(),
			})
			if (exitCode !== 0) {
				finish((stderr || stdout || "").trim() || "Failed to store account secret.")
			}
		})
		waitForReadyFile(readyFile, function(err, payload) {
			logger.debugJSON("storeAccountSecret.readyFile", {
				accountId: accountId,
				key: key,
				err: err || "",
				hasPayload: !!payload,
				port: payload && payload.port ? payload.port : 0,
			})
			if (err) {
				finish(err)
				return
			}
			Requests.postJSON({
				url: "http://127.0.0.1:" + payload.port + "/store",
				headers: {
					"Authorization": "Bearer " + payload.token,
				},
				data: {
					value: value,
				},
			}, function(postErr, data, xhr) {
				logger.debugJSON("storeAccountSecret.postResult", {
					accountId: accountId,
					key: key,
					err: postErr || "",
					status: xhr ? xhr.status : 0,
					ok: !!(data && data.ok === true),
					error: data && data.error ? data.error : "",
				})
				if (postErr || !data || data.ok !== true) {
					finish(postErr || (data && data.error) || "Failed to store account secret.")
				} else {
					finish(null)
				}
			})
		})
	}

	function loadAccountSecret(accountId, key, callback) {
		var readyFile = generateTempFilePath("eventcalendar-secret-read")
		logger.debugJSON("loadAccountSecret.start", {
			accountId: accountId,
			key: key,
			readyFile: readyFile,
		})
		secretExec.execArgv([
			"python3",
			secretStorePath,
			"read-once",
			"--scope",
			"google-account",
			"--key",
			key,
			"--account-id",
			accountId,
			"--ready-file",
			readyFile,
		], function(cmd, exitCode, exitStatus, stdout, stderr) {
			logger.debugJSON("loadAccountSecret.helperExit", {
				accountId: accountId,
				key: key,
				exitCode: exitCode,
				exitStatus: exitStatus,
				stdout: (stdout || "").trim(),
				stderr: (stderr || "").trim(),
			})
		})
		waitForReadyFile(readyFile, function(err, payload) {
			logger.debugJSON("loadAccountSecret.readyFile", {
				accountId: accountId,
				key: key,
				err: err || "",
				hasPayload: !!payload,
				port: payload && payload.port ? payload.port : 0,
			})
			if (err) {
				callback(null, "")
				return
			}
			Requests.getJSON({
				url: "http://127.0.0.1:" + payload.port + "/read",
				headers: {
					"Authorization": "Bearer " + payload.token,
				},
			}, function(readErr, data, xhr) {
				var value = (!readErr && data && data.found && data.value) ? data.value : ""
				logger.debugJSON("loadAccountSecret.result", {
					accountId: accountId,
					key: key,
					err: readErr || "",
					status: xhr ? xhr.status : 0,
					found: !!(data && data.found),
					length: value.length,
				})
				callback(null, value)
			})
		})
	}

	function clearAccountSecret(accountId, key, callback) {
		secretExec.execArgv([
			"python3",
			secretStorePath,
			"clear",
			"--scope",
			"google-account",
			"--key",
			key,
			"--account-id",
			accountId,
		], function(cmd, exitCode, exitStatus, stdout, stderr) {
			if (typeof callback === "function") {
				if (exitCode === 0) {
					callback(null)
				} else {
					callback((stderr || stdout || "").trim() || "Failed to clear account secret.")
				}
			}
		})
	}

	function storeRefreshToken(accountId, refreshToken, callback) {
		storeAccountSecret(accountId, "refresh_token", refreshToken, callback)
	}

	function loadRefreshToken(accountId, callback) {
		loadAccountSecret(accountId, "refresh_token", callback)
	}

	function clearRefreshToken(accountId, callback) {
		clearAccountSecret(accountId, "refresh_token", callback)
	}

	function storeSessionClientSecret(accountId, sessionClientSecret, callback) {
		storeAccountSecret(accountId, "client_secret", sessionClientSecret, callback)
	}

	function loadSessionClientSecret(accountId, callback) {
		loadAccountSecret(accountId, "client_secret", callback)
	}

	function clearSessionClientSecret(accountId, callback) {
		clearAccountSecret(accountId, "client_secret", callback)
	}

	function loadStoredSecrets() {
		for (var i = 0; i < accounts.length; i++) {
			(function(accountId) {
				loadRefreshToken(accountId, function(err, refreshToken) {
					var account = getAccount(accountId)
					if (!err && GoogleAccountState.shouldApplyStoredRefreshToken(account, refreshToken)) {
						updateAccountSecret(accountId, {
							refreshToken: refreshToken,
						})
					}
				})
				loadSessionClientSecret(accountId, function(err, sessionClientSecret) {
					var account = getAccount(accountId)
					if (!err && GoogleAccountState.shouldApplyStoredSessionClientSecret(account, sessionClientSecret)) {
						updateAccountSecret(accountId, {
							sessionClientSecret: sessionClientSecret,
						})
					}
				})
			})(accounts[i].id)
		}
	}

	function migrateLegacyAccountIfNeeded() {
		if (accounts.length > 0) {
			clearLegacyStandaloneConfig()
			return
		}
		if (!readConfig("accessToken", "") && !readConfig("refreshToken", "")) {
			return
		}
		var legacyCalendarList = decodeLegacyBase64Json(readConfig("calendarList", ""))
		var legacyTasklistList = decodeLegacyBase64Json(readConfig("tasklistList", ""))
		var account = {
			id: generateId(),
			label: deriveLabelFromCalendars(legacyCalendarList),
			skipSecretStorage: true,
			sessionClientId: readConfig("sessionClientId", ""),
			sessionClientSecret: readConfig("sessionClientSecret", ""),
			accessToken: readConfig("accessToken", ""),
			accessTokenType: readConfig("accessTokenType", ""),
			accessTokenExpiresAt: readConfig("accessTokenExpiresAt", 0),
			refreshToken: readConfig("refreshToken", ""),
			calendarList: legacyCalendarList,
			calendarIdList: parseLegacyList(readConfig("calendarIdList", "")),
			tasklistList: legacyTasklistList,
			tasklistIdList: parseLegacyList(readConfig("tasklistIdList", "")),
		}
		migrateSecretsToSecretStore([account], function(err) {
			if (err) {
				logger.log('Could not migrate legacy Google account secrets:', err)
				return
			}
			addAccount(account)
			if (account.id) {
				setActiveAccountId(account.id)
			}
			clearLegacyStandaloneConfig()
		})
	}

	function clearLegacyStandaloneConfig() {
		writeConfig("sessionClientId", "")
		writeConfig("sessionClientSecret", "")
		writeConfig("accessToken", "")
		writeConfig("accessTokenType", "")
		writeConfig("accessTokenExpiresAt", 0)
		writeConfig("refreshToken", "")
		writeConfig("calendarList", "")
		writeConfig("calendarIdList", "")
		writeConfig("tasklistList", "")
		writeConfig("tasklistIdList", "")
	}
}
