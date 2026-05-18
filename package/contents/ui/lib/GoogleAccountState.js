function accountById(accounts, accountId) {
	if (!Array.isArray(accounts) || !accountId) {
		return null
	}
	for (var i = 0; i < accounts.length; i++) {
		if (accounts[i] && accounts[i].id === accountId) {
			return accounts[i]
		}
	}
	return null
}

function preserveRuntimeCredentials(account, existingAccount) {
	if (!account || !existingAccount) {
		return account
	}
	if (!account.accessToken && existingAccount.accessToken) {
		account.accessToken = existingAccount.accessToken
		account.accessTokenType = existingAccount.accessTokenType || account.accessTokenType || ""
		account.accessTokenExpiresAt = existingAccount.accessTokenExpiresAt || account.accessTokenExpiresAt || 0
	}
	if (!account.refreshToken && existingAccount.refreshToken) {
		account.refreshToken = existingAccount.refreshToken
	}
	if (!account.sessionClientSecret && existingAccount.sessionClientSecret) {
		account.sessionClientSecret = existingAccount.sessionClientSecret
	}
	return account
}

function preserveRuntimeCredentialsForAccounts(accounts, existingAccounts) {
	if (!Array.isArray(accounts)) {
		return accounts
	}
	for (var i = 0; i < accounts.length; i++) {
		var account = accounts[i]
		preserveRuntimeCredentials(account, accountById(existingAccounts, account && account.id))
	}
	return accounts
}

function shouldApplyStoredRefreshToken(account, refreshToken) {
	return !!(account && refreshToken && !account.refreshToken)
}

function shouldApplyStoredSessionClientSecret(account, sessionClientSecret) {
	return !!(account && sessionClientSecret && !account.sessionClientSecret)
}

function primitiveString(value) {
	var type = typeof value
	if (type === "string" || type === "number" || type === "boolean") {
		return String(value)
	}
	return ""
}

function primitiveNumber(value) {
	var type = typeof value
	if (type !== "number" && type !== "string") {
		return 0
	}
	var numberValue = Number(value)
	return isFinite(numberValue) ? numberValue : 0
}

function primitiveStringList(value) {
	if (!Array.isArray(value)) {
		return []
	}
	var list = []
	for (var i = 0; i < value.length; i++) {
		var item = primitiveString(value[i])
		if (item) {
			list.push(item)
		}
	}
	return list
}

function copyStringField(source, target, key) {
	var value = source && primitiveString(source[key])
	if (value) {
		target[key] = value
	}
}

function serializableCalendar(calendar) {
	var safe = {}
	copyStringField(calendar, safe, "id")
	copyStringField(calendar, safe, "summary")
	copyStringField(calendar, safe, "description")
	copyStringField(calendar, safe, "backgroundColor")
	copyStringField(calendar, safe, "foregroundColor")
	copyStringField(calendar, safe, "accessRole")
	copyStringField(calendar, safe, "timeZone")
	if (calendar && typeof calendar.primary === "boolean") {
		safe.primary = calendar.primary
	}
	return safe
}

function serializableTasklist(tasklist) {
	var safe = {}
	copyStringField(tasklist, safe, "id")
	copyStringField(tasklist, safe, "title")
	return safe
}

function serializableList(list, mapper) {
	if (!Array.isArray(list)) {
		return []
	}
	var safeList = []
	for (var i = 0; i < list.length; i++) {
		safeList.push(mapper(list[i]))
	}
	return safeList
}

function serializeAccountForConfig(account) {
	return {
		id: primitiveString(account && account.id),
		label: primitiveString(account && account.label),
		sessionClientId: primitiveString(account && account.sessionClientId),
		sessionUsesPkce: !!(account && account.sessionUsesPkce === true),
		accessTokenType: primitiveString(account && account.accessTokenType),
		accessTokenExpiresAt: primitiveNumber(account && account.accessTokenExpiresAt),
		calendarList: serializableList(account && account.calendarList, serializableCalendar),
		calendarIdList: primitiveStringList(account && account.calendarIdList),
		calendarSelectionInitialized: !!(account && account.calendarSelectionInitialized === true),
		tasklistList: serializableList(account && account.tasklistList, serializableTasklist),
		tasklistIdList: primitiveStringList(account && account.tasklistIdList),
	}
}

if (typeof module !== "undefined") {
	module.exports = {
		accountById: accountById,
		preserveRuntimeCredentials: preserveRuntimeCredentials,
		preserveRuntimeCredentialsForAccounts: preserveRuntimeCredentialsForAccounts,
		shouldApplyStoredRefreshToken: shouldApplyStoredRefreshToken,
		shouldApplyStoredSessionClientSecret: shouldApplyStoredSessionClientSecret,
		serializeAccountForConfig: serializeAccountForConfig,
	}
}
