const assert = require('assert')
const fs = require('fs')
const path = require('path')

const plasmaCalendarManager = fs.readFileSync(
	path.join(__dirname, '../package/contents/ui/calendars/PlasmaCalendarManager.qml'),
	'utf8'
)

assert.ok(
	!plasmaCalendarManager.includes("logger.debugJSON('PlasmaCalendar', day, dayEvents)"),
	'PlasmaCalendarManager must not log raw local calendar event payloads'
)

console.log('PASS no_raw_plasma_calendar_debug_logs')
