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

function testSerializesAccountWithoutRecursiveApiPayloadsOrSecrets() {
	const calendar = {
		id: 'primary',
		summary: 'Primary Calendar',
		description: 'Personal calendar',
		backgroundColor: '#2952a3',
		foregroundColor: '#ffffff',
		accessRole: 'owner',
		primary: true,
		timeZone: 'Etc/UTC',
	}
	calendar.self = calendar

	const tasklist = {
		id: 'tasks-1',
		title: 'Tasks',
		self: null,
	}
	tasklist.self = tasklist
	const recursiveExpiresAt = {}
	recursiveExpiresAt.self = recursiveExpiresAt

	const serialized = state.serializeAccountForConfig({
		id: 'acc_1',
		label: 'primary@example.test',
		sessionClientId: 'client-id',
		sessionUsesPkce: true,
		accessToken: 'ya29.secret',
		accessTokenType: 'Bearer',
		accessTokenExpiresAt: recursiveExpiresAt,
		refreshToken: '1//secret',
		sessionClientSecret: 'client-secret',
		calendarList: [calendar],
		calendarIdList: ['primary'],
		calendarSelectionInitialized: true,
		tasklistList: [tasklist],
		tasklistIdList: ['tasks-1'],
	})

	assert.doesNotThrow(() => JSON.stringify(serialized))
	assert.strictEqual(serialized.accessToken, undefined)
	assert.strictEqual(serialized.refreshToken, undefined)
	assert.strictEqual(serialized.sessionClientSecret, undefined)
	assert.strictEqual(serialized.accessTokenExpiresAt, 0)
	assert.deepStrictEqual(serialized.calendarList, [{
		id: 'primary',
		summary: 'Primary Calendar',
		description: 'Personal calendar',
		backgroundColor: '#2952a3',
		foregroundColor: '#ffffff',
		accessRole: 'owner',
		primary: true,
		timeZone: 'Etc/UTC',
	}])
	assert.deepStrictEqual(serialized.tasklistList, [{
		id: 'tasks-1',
		title: 'Tasks',
	}])
}

testPreservesRuntimeCredentialsForSameAccount()
testDoesNotCopyCredentialsAcrossAccounts()
testKeepsNewerSerializedValues()
testAppliesStoredRefreshTokenOnlyWhenMemoryIsEmpty()
testAppliesStoredSessionClientSecretOnlyWhenMemoryIsEmpty()
testSerializesAccountWithoutRecursiveApiPayloadsOrSecrets()

console.log('PASS google_account_state')
