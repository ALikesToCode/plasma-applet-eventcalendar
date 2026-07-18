const assert = require('assert')
const fs = require('fs')
const path = require('path')

const html = fs.readFileSync(path.join(__dirname, '../docs/index.html'), 'utf8')
const contributing = fs.readFileSync(path.join(__dirname, '../CONTRIBUTING.md'), 'utf8')

assert.ok(
	html.includes('prism-tomorrow.min.css'),
	'docs/index.html must load a Prism theme for command blocks'
)

assert.ok(
	html.includes('prism-toolbar.min.js') && html.includes('prism-copy-to-clipboard.min.js'),
	'docs/index.html must load Prism toolbar and copy-to-clipboard plugins'
)

assert.ok(
	html.indexOf('prism-toolbar.min.js') < html.indexOf('prism-copy-to-clipboard.min.js'),
	'Prism toolbar must load before copy-to-clipboard'
)

const commandBlocks = [...html.matchAll(/<pre\b([^>]*)>\s*<code\b([^>]*)>/g)]

assert.ok(commandBlocks.length >= 2, 'docs/index.html must include install and update command blocks')

for (const [, preAttrs, codeAttrs] of commandBlocks) {
	assert.match(preAttrs, /class="[^"]*\bcode-block\b[^"]*\bcommand-line\b[^"]*"/, 'command blocks must use Prism command-line plugin')
	assert.match(preAttrs, /data-prompt="\$"/, 'command blocks must show a shell prompt')
	assert.match(codeAttrs, /class="[^"]*\blanguage-bash\b[^"]*"/, 'command blocks must declare bash syntax highlighting')
}

assert.ok(
	html.includes('git clone -b master') && contributing.includes('git clone -b master'),
	'website and contributor setup must target the active master branch'
)
assert.doesNotMatch(
	html,
	/sh \.\/(?:install|update)/,
	'website commands must honor the Bash shebangs'
)
const contributingFences = contributing.match(/^```.*$/gm) || []
assert.equal(contributingFences.length % 2, 0, 'contributor code fences must be balanced')
for (let index = 0; index < contributingFences.length; index += 2) {
	assert.equal(
		contributingFences[index],
		'```bash',
		'contributor code fences must declare a language'
	)
}

console.log('PASS docs_command_blocks')
