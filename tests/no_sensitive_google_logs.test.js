const assert = require('assert')
const fs = require('fs')
const path = require('path')

const loginManager = fs.readFileSync(
	path.join(__dirname, '../package/contents/ui/config/GoogleLoginManager.qml'),
	'utf8'
)

assert.ok(
	!loginManager.includes("logger.debug('/oauth2/v4/token Response', data)"),
	'GoogleLoginManager must not log the raw OAuth token response'
)

console.log('PASS no_sensitive_google_logs')
