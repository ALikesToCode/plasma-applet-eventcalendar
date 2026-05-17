const assert = require('assert')

const events = require('../package/contents/ui/calendars/PlasmaCalendarEventState.js')

function event(id, summary) {
	return {
		id,
		summary,
		start: { date: '2026-05-01' },
		end: { date: '2026-05-02' },
	}
}

const deduped = events.dedupeParsedEvents([
	event('plasma_Holidays_1', 'Loyalty Day'),
	event('plasma_Holidays_1', 'Loyalty Day'),
	event('plasma_Events_1', 'Loyalty Day'),
])

assert.deepStrictEqual(
	deduped.map(item => item.id),
	['plasma_Holidays_1', 'plasma_Events_1']
)

console.log('PASS plasma_calendar_event_state')
