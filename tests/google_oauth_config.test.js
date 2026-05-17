const assert = require('assert')

const config = require('../package/contents/ui/lib/GoogleOAuthConfig.js')

const defaultClientId = '352447874752-sej1ldpd6piqgovtpog0dr91tb4sq5q3.apps.googleusercontent.com'

assert.match(
	config.authConfigurationError(defaultClientId, '', defaultClientId),
	/built-in Google OAuth client/
)

assert.strictEqual(
	config.authConfigurationError('custom-desktop.apps.googleusercontent.com', '', defaultClientId),
	''
)

assert.strictEqual(
	config.authConfigurationError(defaultClientId, 'stored-secret', defaultClientId),
	''
)

assert.match(
	config.authConfigurationError('', '', defaultClientId),
	/Missing Google OAuth client ID/
)

assert.deepStrictEqual(
	config.effectiveClientCredentials({
		customClientId: '',
		customClientSecret: '',
		latestClientId: 'latest-client.apps.googleusercontent.com',
		latestClientSecret: 'latest-secret',
		useDesktopClient: false,
	}, defaultClientId),
	{
		clientId: 'latest-client.apps.googleusercontent.com',
		clientSecret: 'latest-secret',
	}
)

assert.deepStrictEqual(
	config.effectiveClientCredentials({
		customClientId: 'custom-client.apps.googleusercontent.com',
		customClientSecret: '',
		latestClientId: 'latest-client.apps.googleusercontent.com',
		latestClientSecret: 'latest-secret',
		useDesktopClient: false,
	}, defaultClientId),
	{
		clientId: 'custom-client.apps.googleusercontent.com',
		clientSecret: '',
	}
)

console.log('PASS google_oauth_config')
