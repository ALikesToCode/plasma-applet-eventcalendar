const assert = require('assert')
const fs = require('fs')
const path = require('path')

const source = fs.readFileSync(
	path.join(__dirname, '../package/contents/ui/lib/GoogleAccountsStore.qml'),
	'utf8'
)

assert.ok(
	!source.includes('sessionClientSecret: account.sessionClientSecret'),
	'GoogleAccountsStore must not serialize sessionClientSecret into googleAccounts'
)

assert.ok(
	source.includes('account.refreshToken || account.accessToken || account.sessionClientSecret'),
	'sessionClientSecret must trigger one-time secret-store migration before serialization'
)

assert.ok(
	source.includes('storeMigrationSecret(storeSessionClientSecret, account.id, account.sessionClientSecret)'),
	'GoogleAccountsStore must migrate per-account sessionClientSecret to secret storage'
)

assert.ok(
	source.includes('loadSessionClientSecret(accountId'),
	'GoogleAccountsStore must load per-account sessionClientSecret from secret storage'
)

assert.ok(
	source.includes('migrateSecretsToSecretStore(parsed, function(err)'),
	'GoogleAccountsStore must wait for secret-store migration before serializing secrets away'
)

assert.ok(
	!source.includes('migrateSecretsToSecretStore(parsed)\n\t\t\tserialize()'),
	'GoogleAccountsStore must not immediately serialize after starting async secret-store migration'
)

assert.ok(
	source.includes('migrateSecretsToSecretStore([account], function(err)'),
	'legacy standalone migration must wait for secret-store migration before clearing old config'
)

console.log('PASS google_account_store_serialization')
