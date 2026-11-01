const assert = require('assert')

const selection = require('../package/contents/ui/lib/CalendarSelection.js')

const account = 'me@example.com'
const calendars = [
	{ id: 'acc::school', summary: account + ' - School', calendarName: 'School', accountLabel: account, accessRole: 'reader' },
	{ id: 'acc::family', summary: account + ' - Family', calendarName: 'Family', accountLabel: account, accessRole: 'owner' },
	{ id: 'acc::me', summary: account + ' - ' + account, calendarName: account, accountLabel: account, accessRole: 'owner', primary: true },
	{ id: 'acc::tasks', summary: account + ' - My Tasks', calendarName: 'My Tasks', accountLabel: account, accessRole: 'owner', isTasklist: true },
]

// Without a remembered calendar, the primary calendar is chosen, not the
// first writable one.
let choices = selection.buildChoices(calendars, '')
assert.deepStrictEqual(choices.list.map(c => c.calendarId), ['acc::family', 'acc::me', 'acc::tasks'])
assert.strictEqual(choices.list[choices.selectedIndex].calendarId, 'acc::me')

// A remembered calendar wins over the primary one.
choices = selection.buildChoices(calendars, 'acc::tasks')
assert.strictEqual(choices.list[choices.selectedIndex].calendarId, 'acc::tasks')

// A remembered read-only calendar is still listed and selected.
choices = selection.buildChoices(calendars, 'acc::school')
assert.strictEqual(choices.list[choices.selectedIndex].calendarId, 'acc::school')

// Without a primary calendar, the first choice is selected.
choices = selection.buildChoices(calendars.filter(c => !c.primary), 'missing')
assert.strictEqual(choices.selectedIndex, 0)
assert.deepStrictEqual(selection.buildChoices([], '').list, [])

// Labels lead with the calendar name, so a narrow picker shows it.
assert.strictEqual(selection.choiceLabel(calendars[1]), 'Family (me@example.com)')
assert.strictEqual(selection.choiceLabel(calendars[3]), 'My Tasks (me@example.com)')
assert.strictEqual(selection.choiceLabel(calendars[2]), account)
assert.strictEqual(selection.choiceLabel({ summary: 'Local' }), 'Local')

console.log('PASS calendar_selection')
