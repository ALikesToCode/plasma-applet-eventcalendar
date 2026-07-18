const assert = require('assert')
const fs = require('fs')
const path = require('path')

function read(relativePath) {
	return fs.readFileSync(path.join(__dirname, '..', relativePath), 'utf8')
}

const eventModel = read('package/contents/ui/EventModel.qml')
const manager = read('package/contents/ui/calendars/ICalManager.qml')

assert.ok(
	eventModel.includes('bindSignals(icalManager)'),
	'EventModel must bind the iCalendar manager into the shared fetch lifecycle'
)
assert.ok(
	manager.includes('icalManager.asyncRequests += 1')
		&& !manager.includes('icalManager.asyncRequests += 0'),
	'each iCalendar subprocess must be counted as an asynchronous request'
)
assert.ok(
	manager.includes('} finally {\n\t\t\t\ticalManager.asyncRequestsDone += 1'),
	'iCalendar requests must complete exactly once on success and failure'
)
assert.ok(
	manager.includes('if (err) {')
		&& manager.indexOf('if (err) {') < manager.indexOf('setCalendarData(calendarData.url, data)'),
	'failed helper responses must not be dereferenced or stored as event data'
)
assert.ok(
	manager.includes('calendarData.show !== false'),
	'disabled iCalendar feeds must not be fetched or displayed'
)
assert.ok(
	manager.includes('Array.isArray(parsed.items)'),
	'the helper response must be validated before calendar parsing'
)
assert.ok(
	manager.indexOf('callback(null, parsed)') > manager.indexOf('} catch (err) {'),
	'consumer callbacks must run outside the JSON parse catch to avoid double completion'
)
assert.ok(
	!manager.includes("logger.debug('ical.fetchEvents', calendarData.url)"),
	'private published-calendar URLs must not be written to debug logs'
)

console.log('PASS ical_manager_lifecycle')
