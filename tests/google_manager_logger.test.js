const assert = require('assert')
const fs = require('fs')
const path = require('path')

function read(relativePath) {
	return fs.readFileSync(path.join(__dirname, '..', relativePath), 'utf8')
}

function assertOwnsLogger(relativePath) {
	const source = read(relativePath)
	assert.ok(
		source.includes('import "../lib"'),
		`${relativePath} must import shared QML components for its local Logger`
	)
	assert.ok(
		/Logger\s*\{\s*\n\s*id:\s*logger/.test(source),
		`${relativePath} must own a logger so async callbacks do not depend on ambient IDs`
	)
}

assertOwnsLogger('package/contents/ui/calendars/GoogleCalendarManager.qml')
assertOwnsLogger('package/contents/ui/calendars/GoogleTasksManager.qml')

console.log('PASS google_manager_logger')
