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
assert.ok(
	rootBuild.includes('python3 -m zipfile -c "$filename" ./*'),
	'packaging must fall back to Python when the external zip command is unavailable'
)
assert.ok(
	rootBuild.includes('command -v zip > /dev/null 2>&1'),
	'the optional zip probe must not emit an expected command-not-found error'
)
assert.ok(
	rootBuild.includes('if ! (cd package/translate && bash ./build); then'),
	'translation compilation failures must stop packaging'
)

for (const helper of ['package/translate/build', 'package/translate/merge']) {
	const source = read(helper)
	assert.ok(source.startsWith('#!/usr/bin/env bash\n'), `${helper} must declare Bash`)
	assert.ok(
		source.includes('exec /usr/bin/env bash "$0" "$@"'),
		`${helper} must recover when a user invokes it through sh`
	)
}

const translationBuild = read('package/translate/build')
assert.ok(
	translationBuild.includes('set -euo pipefail'),
	'translation compilation must fail on command errors'
)
assert.ok(
	translationBuild.indexOf('mkdir -p "$(dirname "$installPath")"')
		< translationBuild.indexOf('installPath=$(realpath -- "$installPath")'),
	'translation destination directories must exist before canonicalization'
)

const translationMerge = read('package/translate/merge')
assert.ok(
	translationMerge.includes("grep -Eq '(i18n|ki18n|xi18n|I18N_NOOP|tr2i18n|tr2xi18n|N_)"),
	'translation extraction must skip source files without translation calls'
)

console.log('PASS build_shell_runtime')
