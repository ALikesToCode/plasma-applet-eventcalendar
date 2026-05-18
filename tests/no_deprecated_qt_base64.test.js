const assert = require('assert')
const fs = require('fs')
const path = require('path')

const files = [
	'../package/contents/ui/lib/Base64Compat.js',
	'../package/contents/ui/Logic.qml',
	'../package/contents/ui/config/ConfigSerializedString.qml',
	'../package/contents/ui/lib/Base64Json.qml',
	'../package/contents/ui/lib/ConfigAdvanced.qml',
	'../package/contents/ui/lib/GoogleAccountsStore.qml',
	'../package/contents/ui/lib/Pkce.js',
]

for (const relativePath of files) {
	const source = fs.readFileSync(path.join(__dirname, relativePath), 'utf8')
	assert.ok(!source.includes('Qt.btoa('), `${relativePath} must not call Qt.btoa directly`)
	assert.ok(!source.includes('Qt.atob('), `${relativePath} must not call Qt.atob directly`)
}

console.log('PASS no_deprecated_qt_base64')
