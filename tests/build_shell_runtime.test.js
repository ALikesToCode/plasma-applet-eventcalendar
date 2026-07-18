const assert = require('assert')
const fs = require('fs')
const path = require('path')

function read(relativePath) {
	return fs.readFileSync(path.join(__dirname, '..', relativePath), 'utf8')
}

const rootBuild = read('build')

assert.ok(
	rootBuild.includes('(cd package/translate && bash ./merge)')
		&& rootBuild.includes('(cd package/translate && bash ./build)'),
	'the packaging workflow must invoke Bash-only translation helpers with Bash'
)

for (const helper of ['package/translate/build', 'package/translate/merge']) {
	const source = read(helper)
	assert.ok(source.startsWith('#!/usr/bin/env bash\n'), `${helper} must declare Bash`)
	assert.ok(
		source.includes('exec /usr/bin/env bash "$0" "$@"'),
		`${helper} must recover when a user invokes it through sh`
	)
}

console.log('PASS build_shell_runtime')
