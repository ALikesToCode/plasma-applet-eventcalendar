const assert = require('assert')
const fs = require('fs')
const path = require('path')

// Qt 6.12 passes signal arguments of type var as copies, so event parsing must
// not depend on a signal handler mutating its arguments.
function read(relativePath) {
	return fs.readFileSync(path.join(__dirname, '..', relativePath), 'utf8')
}

const calendarsDir = 'package/contents/ui/calendars'
for (const file of fs.readdirSync(path.join(__dirname, '..', calendarsDir))) {
	if (!file.endsWith('.qml')) {
		continue
	}
	const source = read(path.join(calendarsDir, file))
	assert.ok(
		!/\bon(Calendar|Event)Parsing\s*:/.test(source) && !/signal\s+(calendar|event)Parsing\b/.test(source),
		`${file} must parse events through parseCalendar()/parseCalendarEvents(), not signal handlers`
	)
}

const eventModel = read('package/contents/ui/EventModel.qml')
assert.ok(
	eventModel.includes('calendarManager.eventsByCalendar[calendarId]'),
	'EventModel must share the manager\'s calendar data instead of the signal argument copy'
)
