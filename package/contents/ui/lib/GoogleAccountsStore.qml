import QtQuick

import "ConfigUtils.js" as ConfigUtils
import "Requests.js" as Requests
import "SafeConfig.js" as SafeConfig

Item {
	id: store
	visible: false

	property string accountsKey: "googleAccounts"
	property string activeAccountKey: "googleActiveAccountId"

	property var configBridge: null
	property string secretStorePath: {
		var resolved = String(Qt.resolvedUrl("../../scripts/secret_store.py"))
		return resolved.indexOf("file://") === 0 ? resolved.slice(7) : resolved
	}

	property var accountsConfigValue: ""
	property string activeAccountId: ""

	property var accounts: []

	signal accountUpdated(string accountId)

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
		if (hasSameAccountIds(accounts, parsed)) {
			for (var i = 0; i < parsed.length; i++) {
				accounts[i] = parsed[i]
				accountUpdated(parsed[i].id)
			}
		} else {
			accounts = parsed
		}
		if (needsSecretMigration) {
			migrateSecretsToSecretStore(parsed)
			serialize()
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

	function serializeAccount(account) {
		return {
			id: account.id,
			label: account.label,
			sessionClientId: account.sessionClientId,
			sessionUsesPkce: account.sessionUsesPkce === true,
			accessTokenType: account.accessTokenType,
			accessTokenExpiresAt: account.accessTokenExpiresAt,
			calendarList: account.calendarList,
			calendarIdList: account.calendarIdList,
			calendarSelectionInitialized: account.calendarSelectionInitialized === true,
			tasklistList: account.tasklistList,
			tasklistIdList: account.tasklistIdList,
		}
	}

	function serialize() {
		var safeAccounts = (accounts || []).map(serializeAccount)
		var payload = Qt.btoa(JSON.stringify(safeAccounts))
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
		if (!normalized.calendarIdList.length && !skipDefaultSelection) {
			normalized.calendarIdList = ["primary"]
			normalized.calendarSelectionInitialized = true
		}
		var nextAccounts = accounts.slice(0)
		nextAccounts.push(normalized)
		accounts = nextAccounts
		if (normalized.refreshToken) {
			storeRefreshToken(normalized.id, normalized.refreshToken)
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
			storeRefreshToken(accountId, patch.refreshToken || "")
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
		serialize()
		if (activeAccountId === accountId) {
			setActiveAccountId(accounts.length ? accounts[0].id : "")
		}
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

	function migrateSecretsToSecretStore(list) {
		for (var i = 0; i < list.length; i++) {
			var account = list[i]
			if (account && account.refreshToken) {
				storeRefreshToken(account.id, account.refreshToken)
			}
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

	function storeRefreshToken(accountId, refreshToken, callback) {
		if (!accountId) {
			if (typeof callback === "function") {
				callback("Missing account id.")
			}
			return
		}
		if (!refreshToken) {
			clearRefreshToken(accountId, callback)
			return
		}
		var readyFile = generateTempFilePath("eventcalendar-secret-store")
		secretExec.execArgv([
			"python3",
			secretStorePath,
			"store-once",
			"--scope",
			"google-account",
			"--key",
			"refresh_token",
			"--account-id",
			accountId,
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

	function loadRefreshToken(accountId, callback) {
		secretExec.execArgv([
			"python3",
			secretStorePath,
			"read",
			"--scope",
			"google-account",
			"--key",
			"refresh_token",
			"--account-id",
			accountId,
		], function(cmd, exitCode, exitStatus, stdout, stderr) {
			var value = (stdout || "").replace(/\n+$/g, "")
			if (exitCode !== 0 && !value) {
				callback(null, "")
				return
			}
			callback(null, value)
		})
	}

	function clearRefreshToken(accountId, callback) {
		secretExec.execArgv([
			"python3",
			secretStorePath,
			"clear",
			"--scope",
			"google-account",
			"--key",
			"refresh_token",
			"--account-id",
			accountId,
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

	function loadStoredSecrets() {
		for (var i = 0; i < accounts.length; i++) {
			(function(accountId) {
				loadRefreshToken(accountId, function(err, refreshToken) {
					if (!err && refreshToken) {
						updateAccountSecret(accountId, {
							refreshToken: refreshToken,
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
		addAccount(account)
		if (account.id) {
			setActiveAccountId(account.id)
		}
		clearLegacyStandaloneConfig()
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
