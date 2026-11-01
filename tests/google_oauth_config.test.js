const assert = require('assert')
const fs = require('fs')
const path = require('path')

const config = require('../package/contents/ui/lib/GoogleOAuthConfig.js')

const builtIn = {
	clientId: config.builtInClientId,
	clientSecret: config.builtInClientSecret,
}

// The built-in client is a Desktop client, and Google's token endpoint
// requires its secret.
assert.match(config.builtInClientId, /^\d+-[a-z0-9]+\.apps\.googleusercontent\.com$/)
assert.match(config.builtInClientSecret, /^GOCSPX-\S+$/)

// With nothing configured, use the built-in client with its secret.
assert.deepStrictEqual(config.effectiveClientCredentials({}), builtIn)
assert.deepStrictEqual(config.effectiveClientCredentials(undefined), builtIn)
assert.deepStrictEqual(config.effectiveClientCredentials({
	latestClientId: config.builtInClientId,
	latestClientSecret: '',
	useDesktopClient: true,
}), builtIn)

// A client saved without its secret can't sign in, so it falls through to
// the built-in client.
assert.deepStrictEqual(config.effectiveClientCredentials({
	latestClientId: 'old-client.apps.googleusercontent.com',
	latestClientSecret: '',
	useDesktopClient: false,
}), builtIn)

// A client saved with its secret by an older version is still used, unless
// the user picks the built-in client.
const latest = {
	customClientId: '',
	customClientSecret: '',
	latestClientId: 'latest-client.apps.googleusercontent.com',
	latestClientSecret: 'latest-secret',
	useDesktopClient: false,
}
assert.deepStrictEqual(config.effectiveClientCredentials(latest), {
	clientId: 'latest-client.apps.googleusercontent.com',
	clientSecret: 'latest-secret',
})
assert.deepStrictEqual(
	config.effectiveClientCredentials(Object.assign({}, latest, { useDesktopClient: true })),
	builtIn
)

// The user's own client wins, even without a secret.
assert.deepStrictEqual(
	config.effectiveClientCredentials(Object.assign({}, latest, {
		customClientId: ' custom-client.apps.googleusercontent.com ',
	})),
	{
		clientId: 'custom-client.apps.googleusercontent.com',
		clientSecret: '',
	}
)
assert.deepStrictEqual(
	config.effectiveClientCredentials({
		customClientId: 'custom-client.apps.googleusercontent.com',
		customClientSecret: ' custom-secret ',
	}),
	{
		clientId: 'custom-client.apps.googleusercontent.com',
		clientSecret: 'custom-secret',
	}
)

// Entering the built-in client ID without a secret fills in its secret.
assert.deepStrictEqual(
	config.effectiveClientCredentials({ customClientId: config.builtInClientId }),
	builtIn
)
assert.strictEqual(config.clientSecretFor(config.builtInClientId, ''), config.builtInClientSecret)
assert.strictEqual(config.clientSecretFor('other.apps.googleusercontent.com', ''), '')

assert.match(config.authConfigurationError(''), /Missing Google OAuth client ID/)
assert.match(config.authConfigurationError('   '), /Missing Google OAuth client ID/)
assert.strictEqual(config.authConfigurationError(config.builtInClientId), '')
assert.strictEqual(config.authConfigurationError('custom-desktop.apps.googleusercontent.com'), '')

// Request only the narrow scopes declared for OAuth verification, never
// full calendar access.
assert.deepStrictEqual(config.requestedScopes, [
	'https://www.googleapis.com/auth/calendar.calendarlist.readonly',
	'https://www.googleapis.com/auth/calendar.events',
	'https://www.googleapis.com/auth/tasks',
])
assert.strictEqual(
	config.authorizationScope(),
	'https://www.googleapis.com/auth/calendar.calendarlist.readonly https://www.googleapis.com/auth/calendar.events https://www.googleapis.com/auth/tasks'
)

// "Use the built-in Google client" picks the built-in client over one saved
// by an older version. Refreshing the credentials must not untick it.
const loginManager = fs.readFileSync(
	path.join(__dirname, '../package/contents/ui/config/GoogleLoginManager.qml'),
	'utf8'
)
assert.ok(
	!loginManager.includes('writeConfig("useDesktopClient", false)'),
	'GoogleLoginManager must not switch the built-in client choice off'
)

console.log('PASS google_oauth_config')
