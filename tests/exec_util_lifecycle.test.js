const assert = require('assert')
const fs = require('fs')
const path = require('path')

const source = fs.readFileSync(
	path.join(__dirname, '../package/contents/ui/lib/ExecUtil.qml'),
	'utf8'
)

function functionBody(startMarker, endMarker) {
	const start = source.indexOf(startMarker)
	const end = source.indexOf(endMarker, start)
	assert.ok(start >= 0 && end > start, `could not find ${startMarker}`)
	return source.slice(start, end)
}

function assertOrdered(body, markers, message) {
	let previous = -1
	for (const marker of markers) {
		const index = body.indexOf(marker)
		assert.ok(index > previous, `${message}: ${marker}`)
		previous = index
	}
}

const completion = functionBody('onNewData: function', '\n\tsignal exited')
assertOrdered(completion, [
	'var listener = listeners[cmd]',
	'delete listeners[cmd]',
	'disconnectSource(sourceName)',
	'listener(cmd, exitCode, exitStatus, stdout, stderr)',
	'exited(cmd, exitCode, exitStatus, stdout, stderr)',
], 'completed sources must be cleaned up before restartable handlers run')

const runCommand = functionBody('function runCommand', '\n\tfunction exec(')
assertOrdered(runCommand, [
	'delete listeners[cmd]',
	'disconnectSource(cmd)',
	"if (typeof callback === 'function')",
	'listeners[cmd] = listener',
	'\n\t\tconnectSource(cmd)',
], 'every replacement run must clear stale state before reconnecting')

assert.ok(
	!runCommand.includes('exited.disconnect'),
	'listener callbacks are not signal connections and must not be disconnected as signals'
)

console.log('PASS exec_util_lifecycle')
