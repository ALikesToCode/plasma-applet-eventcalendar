const assert = require('assert')
const fs = require('fs')
const path = require('path')

const source = fs.readFileSync(path.join(__dirname, '../install'), 'utf8')

assert.ok(
	source.includes('! "$packageNamespace" =~ ^[A-Za-z0-9._-]+$'),
	'install must reject package namespaces that could escape the plasmoid directory'
)
assert.ok(
	source.includes('|| "$packageNamespace" == "."') &&
		source.includes('|| "$packageNamespace" == ".."'),
	'install must reject dot path components before recursive replacement'
)
assert.ok(
	source.includes('PACKAGE_INSTALL_DIR="${INSTALL_DIR:?}/${packageNamespace:?}"'),
	'install must require both path components before constructing the replacement target'
)
assert.ok(
	source.includes('rm -rf -- "$PACKAGE_INSTALL_DIR"'),
	'install must delete only the validated package destination'
)

console.log('PASS install_path_safety')
