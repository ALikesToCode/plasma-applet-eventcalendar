const assert = require('assert')
const fs = require('fs')
const path = require('path')

const source = fs.readFileSync(
	path.join(__dirname, '../package/contents/ui/lib/GoogleAccountsStore.qml'),
	'utf8'
)
const loginManagerSource = fs.readFileSync(
	path.join(__dirname, '../package/contents/ui/config/GoogleLoginManager.qml'),
	'utf8'
)
const eventModelSource = fs.readFileSync(
	path.join(__dirname, '../package/contents/ui/EventModel.qml'),
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

assert.ok(
	source.includes('function updateAccount(accountId, patch, callback)'),
	'GoogleAccountsStore.updateAccount must expose completion so secret writes can gate publishing'
)

assert.ok(
	source.includes('finishUpdate(firstError || null)'),
	'GoogleAccountsStore.updateAccount must finish only after pending secret writes complete'
)

assert.ok(
	source.includes('function updateRequiresSerialize(patch)'),
	'GoogleAccountsStore.updateAccount must distinguish persisted account changes from runtime token updates'
)

assert.ok(
	source.includes('if (updateRequiresSerialize(patch))'),
	'GoogleAccountsStore.updateAccount must not serialize transient access token refreshes'
)

assert.ok(
	source.includes('function parseSecretStoreError(data)'),
	'GoogleAccountsStore must parse secret helper error bodies instead of reporting only HTTP 500'
)

assert.ok(
	source.includes('finish(parseSecretStoreError(data) || postErr'),
	'GoogleAccountsStore must prefer the secret helper error message over a generic HTTP status'
)

assert.ok(
	loginManagerSource.includes('skipSerialize: true'),
	'GoogleLoginManager must not serialize a placeholder account before token storage succeeds'
)

assert.ok(
	loginManagerSource.includes('accountsStore.updateAccount(target.targetId, patch, function(updateErr)'),
	'GoogleLoginManager must wait for account secret persistence before reporting login success'
)

assert.ok(
	loginManagerSource.includes('sessionClientSecret: effectiveClientSecret'),
	'GoogleLoginManager must store the client secret that originally issued each refresh token'
)

assert.ok(
	loginManagerSource.includes("reauthRequired: false")
		&& loginManagerSource.includes("reauthReason: ''"),
	'GoogleLoginManager must clear a terminal refresh error when the selected account reconnects'
)

assert.ok(
	loginManagerSource.includes('&& !existingAccount.reauthRequired'),
	'GoogleLoginManager must not reuse a refresh token that Google has already rejected'
)

assert.ok(
	source.includes('property bool secretsLoaded'),
	'GoogleAccountsStore must expose whether async account secrets have loaded'
)

assert.ok(
	source.includes('function accountCanFetch(account)'),
	'GoogleAccountsStore must identify accounts with usable runtime Google credentials'
)

assert.ok(
	eventModelSource.includes('model: googleAccountsStore.fetchableAccounts'),
	'EventModel must not create Google managers before stored refresh tokens have loaded'
)

console.log('PASS google_account_store_serialization')
