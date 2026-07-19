const assert = require('assert')
const fs = require('fs')
const path = require('path')

const source = fs.readFileSync(path.join(__dirname, '../install'), 'utf8')

assert.ok(
	source.includes('"libsecret-tools"'),
	'Debian installs must include libsecret-tools so Google refresh tokens can be stored'
)

console.log('PASS install_secret_dependencies')
