const assert = require('node:assert/strict')
const fs = require('node:fs')
const path = require('node:path')
const test = require('node:test')
const vm = require('node:vm')

const source = fs.readFileSync(path.join(__dirname, '../package/contents/ui/calendars/GoogleApiSession.qml'), 'utf8')
const start = source.indexOf('function updateAccessToken(callback)')
const end = source.indexOf('\n\tsignal accessTokenError', start)
assert.ok(start >= 0 && end > start)
const updateSource = source.slice(start, end)

function refresh({ storageError = null, refreshToken = 'fixture-refresh', requestError = null, response = '{"access_token":"fixture-access"}' } = {}) {
	const calls = { requests: [], tokens: [], callbacks: [] }
	const context = {
		loadRefreshToken: callback => callback(storageError, refreshToken),
		fetchNewAccessToken(token, callback) {
			calls.requests.push(token)
			callback(requestError, response, {})
		},
		googleApiSession: { applyAccessToken: token => calls.tokens.push(token) },
		logger: { debug() {}, log() {} },
	}
	const update = vm.runInNewContext(`(${updateSource})`, context)
	update(error => calls.callbacks.push(error))
	return calls
}

test('Google refresh applies a valid response and completes once', () => {
	const calls = refresh()
	assert.deepEqual(calls.requests, ['fixture-refresh'])
	assert.equal(calls.tokens.length, 1)
	assert.equal(calls.tokens[0].access_token, 'fixture-access')
	assert.deepEqual(calls.callbacks, [null])
})

for (const [name, options, error] of [
	['missing refresh token', { refreshToken: '' }, 'No refresh token. Cannot update access token.'],
	['secret store error', { storageError: 'storage unavailable' }, 'storage unavailable'],
]) {
	test(`Google refresh rejects ${name} without a request`, () => {
		const calls = refresh(options)
		assert.deepEqual(calls.requests, [])
		assert.deepEqual(calls.tokens, [])
		assert.deepEqual(calls.callbacks, [error])
	})
}

for (const [name, options, error] of [
	['request failure', { requestError: 'request failed' }, 'request failed'],
	['invalid JSON', { response: '<html>failure</html>' }, 'Invalid refresh response.'],
	['OAuth error', { response: '{"error":"invalid_grant","error_description":"expired fixture"}' }, 'expired fixture'],
	['missing access token', { response: '{}' }, 'Missing access token.'],
	['null response', { response: 'null' }, 'Missing access token.'],
]) {
	test(`Google refresh rejects ${name} and completes once`, () => {
		const calls = refresh(options)
		assert.deepEqual(calls.tokens, [])
		assert.deepEqual(calls.callbacks, [error])
	})
}
