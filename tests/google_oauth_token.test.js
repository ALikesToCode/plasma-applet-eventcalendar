const assert = require('assert')

const token = require('../package/contents/ui/lib/GoogleOAuthToken.js')

const invalidGrantBody = JSON.stringify({
	error: 'invalid_grant',
	error_description: 'Token has been expired or revoked.',
	error_subtype: 'invalid_rapt',
})
const invalidGrant = token.parseTokenResponse(invalidGrantBody)

assert.deepStrictEqual(invalidGrant, {
	error: 'invalid_grant',
	error_description: 'Token has been expired or revoked.',
	error_subtype: 'invalid_rapt',
})
assert.strictEqual(token.requiresReauthorization(invalidGrant), true)
assert.match(token.refreshErrorMessage('HTTP Error 400', invalidGrant), /Update Selected/)
assert.deepStrictEqual(token.errorSummary(invalidGrant), {
	error: 'invalid_grant',
	errorSubtype: 'invalid_rapt',
	hasDescription: true,
})

assert.strictEqual(
	token.refreshErrorMessage('HTTP Error 401', {
		error: 'invalid_client',
		error_description: 'The OAuth client was not found.',
	}),
	'The OAuth client was not found.'
)
assert.strictEqual(token.requiresReauthorization({ error: 'invalid_client' }), false)
assert.strictEqual(token.parseTokenResponse('not json'), null)
assert.strictEqual(token.refreshErrorMessage('HTTP Error 500', null), 'HTTP Error 500')

console.log('PASS google_oauth_token')
