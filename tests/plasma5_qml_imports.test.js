const assert = require('node:assert/strict')
const fs = require('node:fs')
const path = require('node:path')
const test = require('node:test')

const contents = path.join(__dirname, '../package/contents')

function qmlFiles(directory) {
	return fs.readdirSync(directory, { withFileTypes: true }).flatMap(entry => {
		const filename = path.join(directory, entry.name)
		return entry.isDirectory() ? qmlFiles(filename) : filename.endsWith('.qml') ? [filename] : []
	})
}

test('Plasma 5 QML imports specify versions and use Qt 5 modules', () => {
	for (const filename of qmlFiles(contents)) {
		const source = fs.readFileSync(filename, 'utf8')
		for (const match of source.matchAll(/^import\s+([\w.]+)(.*)$/gm)) {
			assert.match(match[2], /^\s+\d+\.\d+\b/, `${filename}: ${match[0]}`)
			assert.notEqual(match[1], 'org.kde.plasma.plasma5support', filename)
			assert.ok(!match[1].startsWith('Qt5Compat.'), filename)
		}
	}
	const executable = fs.readFileSync(path.join(contents, 'ui/lib/ExecUtil.qml'), 'utf8')
	assert.match(executable, /PlasmaCore\.DataSource\s*\{/)
	assert.match(executable, /engine:\s*"executable"/)
})
