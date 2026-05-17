const assert = require('assert')
const fs = require('fs')
const path = require('path')

const html = fs.readFileSync(path.join(__dirname, '../docs/index.html'), 'utf8')

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

console.log('PASS docs_command_blocks')
