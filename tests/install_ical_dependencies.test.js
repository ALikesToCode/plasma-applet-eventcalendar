const assert = require('assert')
const fs = require('fs')
const path = require('path')

function read(relativePath) {
	return fs.readFileSync(path.join(__dirname, '..', relativePath), 'utf8')
}

const install = read('install')
const update = read('update')
const helper = read('package/contents/scripts/icsjson.py')
const readme = read('ReadMe.md')

for (const [name, source] of [['install', install], ['update', update]]) {
	assert.ok(source.includes('"python3-pip"') && source.includes('"python-pip"'),
		`${name} must provide pip on supported distro families`)
	assert.ok(source.includes("'recurring-ical-events>=3.8,<4'"),
		`${name} must install the recurrence dependency with a compatible version range`)
	assert.ok(source.includes('install_requirements\ninstall_python_calendar_dependencies'),
		`${name} must invoke the user-local recurrence dependency installer`)
	assert.ok(source.includes('.local/share/plasma_org.kde.plasma.eventcalendar/python'),
		`${name} must keep Python dependencies out of the system environment`)
}

assert.ok(
	helper.includes('sys.path.insert(0, LOCAL_PYTHON_DIR)'),
	'the iCalendar helper must load dependencies from the applet data directory'
)
assert.ok(
	readme.includes('recurring-ical-events>=3.8,<4'),
	'the recurrence dependency must be documented for non-script installs'
)

console.log('PASS install_ical_dependencies')
