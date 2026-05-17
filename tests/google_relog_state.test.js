const assert = require('assert')
const fs = require('fs')
const path = require('path')

const logic = fs.readFileSync(
	path.join(__dirname, '../package/contents/ui/Logic.qml'),
	'utf8'
)

assert.ok(
	logic.includes('account.sessionUsesPkce === false'),
	'Logic must not force relog for secret-based accounts that can refresh with per-account stored secrets'
)

assert.ok(
	!logic.includes('account.sessionUsesPkce !== currentGoogleUsesPkce()'),
	'Logic must not compare serialized secret-based accounts against only global current credentials'
)

console.log('PASS google_relog_state')
