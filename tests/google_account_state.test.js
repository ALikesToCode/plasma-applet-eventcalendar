const assert = require('assert')

const state = require('../package/contents/ui/lib/GoogleAccountState.js')

function testPreservesRuntimeCredentialsForSameAccount() {
	const nextAccounts = [{
		id: 'acc_1',
		label: 'primary@example.test',
		accessToken: '',
		accessTokenType: '',
		accessTokenExpiresAt: 0,
		refreshToken: '',
		sessionClientSecret: '',
	}]
	const existingAccounts = [{
		id: 'acc_1',
		accessToken: 'ya29.access',
		accessTokenType: 'Bearer',
		accessTokenExpiresAt: 123456,
		refreshToken: '1//refresh',
		sessionClientSecret: 'secret',
	}]

	state.preserveRuntimeCredentialsForAccounts(nextAccounts, existingAccounts)

	assert.strictEqual(nextAccounts[0].accessToken, 'ya29.access')
	assert.strictEqual(nextAccounts[0].accessTokenType, 'Bearer')
	assert.strictEqual(nextAccounts[0].accessTokenExpiresAt, 123456)
	assert.strictEqual(nextAccounts[0].refreshToken, '1//refresh')
	assert.strictEqual(nextAccounts[0].sessionClientSecret, 'secret')
}

function testDoesNotCopyCredentialsAcrossAccounts() {
	const nextAccounts = [{ id: 'acc_2', accessToken: '', refreshToken: '' }]
	const existingAccounts = [{ id: 'acc_1', accessToken: 'ya29.access', refreshToken: '1//refresh' }]

	state.preserveRuntimeCredentialsForAccounts(nextAccounts, existingAccounts)

	assert.strictEqual(nextAccounts[0].accessToken, '')
	assert.strictEqual(nextAccounts[0].refreshToken, '')
}

function testKeepsNewerSerializedValues() {
	const nextAccounts = [{
		id: 'acc_1',
		accessToken: 'new-token',
		accessTokenType: 'Bearer',
		accessTokenExpiresAt: 200,
		refreshToken: 'new-refresh',
	}]
	const existingAccounts = [{
		id: 'acc_1',
		accessToken: 'old-token',
		accessTokenType: 'Bearer',
		accessTokenExpiresAt: 100,
		refreshToken: 'old-refresh',
	}]

	state.preserveRuntimeCredentialsForAccounts(nextAccounts, existingAccounts)

	assert.strictEqual(nextAccounts[0].accessToken, 'new-token')
	assert.strictEqual(nextAccounts[0].accessTokenExpiresAt, 200)
	assert.strictEqual(nextAccounts[0].refreshToken, 'new-refresh')
}

function testAppliesStoredRefreshTokenOnlyWhenMemoryIsEmpty() {
	assert.strictEqual(
		state.shouldApplyStoredRefreshToken({ id: 'acc_1', refreshToken: '' }, 'stored-refresh'),
		true
	)
	assert.strictEqual(
		state.shouldApplyStoredRefreshToken({ id: 'acc_1', refreshToken: 'runtime-refresh' }, 'stored-refresh'),
		false
	)
	assert.strictEqual(
		state.shouldApplyStoredRefreshToken({ id: 'acc_1', refreshToken: '' }, ''),
		false
	)
}

function testAppliesStoredSessionClientSecretOnlyWhenMemoryIsEmpty() {
	assert.strictEqual(
		state.shouldApplyStoredSessionClientSecret({ id: 'acc_1', sessionClientSecret: '' }, 'stored-secret'),
		true
	)
	assert.strictEqual(
		state.shouldApplyStoredSessionClientSecret({ id: 'acc_1', sessionClientSecret: 'runtime-secret' }, 'stored-secret'),
		false
	)
	assert.strictEqual(
		state.shouldApplyStoredSessionClientSecret({ id: 'acc_1', sessionClientSecret: '' }, ''),
		false
	)
}

testPreservesRuntimeCredentialsForSameAccount()
testDoesNotCopyCredentialsAcrossAccounts()
testKeepsNewerSerializedValues()
testAppliesStoredRefreshTokenOnlyWhenMemoryIsEmpty()
testAppliesStoredSessionClientSecretOnlyWhenMemoryIsEmpty()

console.log('PASS google_account_state')
