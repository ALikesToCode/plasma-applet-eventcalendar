const assert = require('assert')
const fs = require('fs')
const path = require('path')

// eventCreated and eventDeleted pass the calendar ID first. Handlers that
// take only `data` get the ID string and can't show the notification.
const agendaView = fs.readFileSync(path.join(__dirname, '../package/contents/ui/AgendaView.qml'), 'utf8')
assert.ok(agendaView.includes('function onEventCreated(calendarId, data)'))
assert.ok(agendaView.includes('function onEventDeleted(calendarId, eventId, data)'))

console.log('PASS agenda_notification_handlers')
