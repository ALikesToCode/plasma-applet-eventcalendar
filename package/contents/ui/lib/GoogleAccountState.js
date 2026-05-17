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

if (typeof module !== "undefined") {
	module.exports = {
		accountById: accountById,
		preserveRuntimeCredentials: preserveRuntimeCredentials,
		preserveRuntimeCredentialsForAccounts: preserveRuntimeCredentialsForAccounts,
		shouldApplyStoredRefreshToken: shouldApplyStoredRefreshToken,
		shouldApplyStoredSessionClientSecret: shouldApplyStoredSessionClientSecret,
	}
}
