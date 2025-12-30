import QtQuick

import "ConfigUtils.js" as ConfigUtils

QtObject {
	id: store

	property string accountsKey: "googleAccounts"
	property string activeAccountKey: "googleActiveAccountId"

	property var configBridge: null

	property var accountsConfigValue: readConfig(accountsKey, "")
	property string activeAccountId: readConfig(activeAccountKey, "")

	property var accounts: []

	signal accountUpdated(string accountId)

	Component.onCompleted: {
		configBridge = ConfigUtils.findBridge(store)
		loadAccounts()
		migrateLegacyAccountIfNeeded()
	}

	onAccountsConfigValueChanged: loadAccounts()
	onActiveAccountIdChanged: {
		if (activeAccountId && !getAccount(activeAccountId)) {
			ensureActiveAccount()
		}
	}

	function loadAccounts() {
		var parsed = normalizeAccounts(parseAccounts(accountsConfigValue))
		if (hasSameAccountIds(accounts, parsed)) {
			for (var i = 0; i < parsed.length; i++) {
				accounts[i] = parsed[i]
				accountUpdated(parsed[i].id)
			}
		} else {
			accounts = parsed
		}
		ensureActiveAccount()
	}

	function readConfig(key, fallback) {
		if (configBridge) {
			var bridged = configBridge.read(key, undefined)
			if (bridged !== undefined && bridged !== null) {
				return bridged
			}
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
		var decoded = value
		try {
			decoded = Qt.atob(value)
		} catch (e) {
			decoded = value
		}
		try {
			var parsed = JSON.parse(decoded)
			return Array.isArray(parsed) ? parsed : []
		} catch (e2) {
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
		normalized.accessToken = account.accessToken || ""
		normalized.accessTokenType = account.accessTokenType || ""
		normalized.accessTokenExpiresAt = account.accessTokenExpiresAt || 0
		normalized.refreshToken = account.refreshToken || ""
		normalized.calendarList = Array.isArray(account.calendarList) ? account.calendarList : []
		normalized.calendarIdList = ensureStringArray(account.calendarIdList)
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

	function serialize() {
		var payload = Qt.btoa(JSON.stringify(accounts || []))
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
		if (!normalized.calendarIdList.length) {
			normalized.calendarIdList = ["primary"]
		}
		var nextAccounts = accounts.slice(0)
		nextAccounts.push(normalized)
		accounts = nextAccounts
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
		serialize()
		if (activeAccountId === accountId) {
			setActiveAccountId(accounts.length ? accounts[0].id : "")
		}
	}

	function setActiveAccountId(accountId) {
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
		var decoded = value
		try {
			decoded = Qt.atob(value)
		} catch (e) {
			decoded = value
		}
		try {
			var parsed = JSON.parse(decoded)
			return Array.isArray(parsed) ? parsed : []
		} catch (e2) {
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

	function migrateLegacyAccountIfNeeded() {
		if (accounts.length > 0) {
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
	}
}
