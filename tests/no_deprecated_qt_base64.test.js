const assert = require('assert')
const fs = require('fs')
const path = require('path')

const files = [
	'../package/contents/ui/lib/SafeConfig.js',
	'../package/contents/ui/lib/GoogleAccountsStore.qml',
	'../package/contents/ui/lib/ExecUtil.qml',
]

for (const relativePath of files) {
	const source = fs.readFileSync(path.join(__dirname, relativePath), 'utf8')
	assert.ok(!source.includes('Qt.btoa('), `${relativePath} must not call deprecated string Qt.btoa directly`)
	assert.ok(!source.includes('Qt.atob('), `${relativePath} must not call deprecated string Qt.atob directly`)
}

console.log('PASS no_deprecated_qt_base64')
