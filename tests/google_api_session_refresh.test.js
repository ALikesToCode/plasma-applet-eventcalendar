const assert = require('assert')
const fs = require('fs')
const path = require('path')

const source = fs.readFileSync(
	path.join(__dirname, '../package/contents/ui/calendars/GoogleApiSession.qml'),
	'utf8'
)

assert.ok(
	!source.includes('googleApiSession.applyAccessToken(parsed)\n\t\t\tfinishRefresh(null)'),
	'GoogleApiSession must not call finishRefresh after applyAccessToken can invalidate the QML context'
)

assert.ok(
	source.includes('var callbacks = refreshCallbacks.slice(0)\n\t\t\trefreshCallbacks = []\n\t\t\trefreshInFlight = false\n\t\t\tgoogleApiSession.applyAccessToken(parsed)'),
	'GoogleApiSession must capture and clear refresh callbacks before applying a refreshed token'
)

console.log('PASS google_api_session_refresh')
