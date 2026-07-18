const assert = require('assert')
const fs = require('fs')
const path = require('path')

const catalogDirectory = path.join(__dirname, '../package/translate')
const catalogs = fs.readdirSync(catalogDirectory).filter(file => file.endsWith('.po'))

assert.ok(catalogs.length > 0, 'translation catalogs must be present')

for (const catalog of catalogs) {
	const source = fs.readFileSync(path.join(catalogDirectory, catalog), 'utf8')
	assert.doesNotMatch(
		source,
		/nplurals=INTEGER|plural=EXPRESSION/,
		`${catalog} must declare a valid locale-specific plural rule`
	)
}

console.log(`PASS translation_catalogs (${catalogs.length} catalogs)`)
