const assert = require('node:assert/strict')
const fs = require('node:fs')
const os = require('node:os')
const path = require('node:path')
const { spawnSync } = require('node:child_process')
const test = require('node:test')

const repository = path.join(__dirname, '..')
const packageId = 'org.kde.plasma.eventcalendar'

function writeExecutable(filename, source) {
	fs.writeFileSync(filename, '#!/usr/bin/env bash\nset -eu\n' + source, { mode: 0o755 })
}

function writeMockCommands(bin, major) {
	writeExecutable(path.join(bin, 'git'), `
printf 'git %s\n' "$*" >> "$EVENTCALENDAR_TEST_TRACE"
case "$1" in
    rev-parse)
        if [ "$2" = "--git-dir" ]; then echo .git; else cat "$EVENTCALENDAR_TEST_BRANCH"; fi ;;
    diff) exit "${'${EVENTCALENDAR_TEST_DIRTY:-0}'}" ;;
    checkout)
        if [ "$2" = "-b" ]; then branch="$3"; else branch="$2"; fi
        printf '%s' "$branch" > "$EVENTCALENDAR_TEST_BRANCH" ;;
    fetch|show-ref|pull) exit 0 ;;
    *) exit 90 ;;
esac
`)
	writeExecutable(path.join(bin, 'plasmashell'), `printf 'plasmashell ${major}.27.12\n'\n`)
	for (const version of [5, 6]) {
		writeExecutable(path.join(bin, `kpackagetool${version}`), `
printf 'kpackagetool${version} %s\n' "$*" >> "$EVENTCALENDAR_TEST_TRACE"
[ "$1" = "--list-types" ] && echo 'Plasma/Applet'
`)
	}
	for (const command of ['qdbus', 'qdbus6']) {
		writeExecutable(path.join(bin, command), `printf '${command} %s\n' "$*" >> "$EVENTCALENDAR_TEST_TRACE"\n`)
	}
	writeExecutable(path.join(bin, 'sudo'), 'echo "Unexpected package installation" >&2\nexit 91\n')
}

function fixture(t, { major = 5, branch = major === 5 ? 'plasma-5' : 'master', metadata = major === 5 ? 'desktop' : 'json', id = packageId } = {}) {
	const directory = fs.mkdtempSync(path.join(os.tmpdir(), 'eventcalendar-scripts-'))
	t.after(() => fs.rmSync(directory, { recursive: true, force: true }))
	const bin = path.join(directory, 'bin')
	const home = path.join(directory, 'home')
	const packageDirectory = path.join(directory, 'package')
	const installed = path.join(home, '.local/share/plasma/plasmoids', packageId)
	fs.mkdirSync(bin)
	fs.mkdirSync(home)
	fs.mkdirSync(packageDirectory)
	fs.writeFileSync(path.join(packageDirectory, 'content.txt'), 'new package')
	if (metadata === 'desktop') {
		fs.writeFileSync(path.join(packageDirectory, 'metadata.desktop'), `[Desktop Entry]\nX-KDE-PluginInfo-Name=${id}\n`)
	} else if (metadata === 'json') {
		fs.writeFileSync(path.join(packageDirectory, 'metadata.json'), JSON.stringify({ KPlugin: { Id: id } }))
	}
	for (const script of ['install', 'update', 'uninstall']) {
		const source = fs.readFileSync(path.join(repository, script), 'utf8')
		fs.writeFileSync(path.join(directory, script), source.replace(`/tmp/plasma-widget-${script}.log`, path.join(directory, `${script}.log`)))
	}
	if (fs.existsSync(path.join(repository, 'lib'))) {
		fs.cpSync(path.join(repository, 'lib'), path.join(directory, 'lib'), { recursive: true })
	}
	const branchFile = path.join(directory, 'branch')
	fs.writeFileSync(branchFile, branch)
	writeMockCommands(bin, major)
	const traceFile = path.join(directory, 'trace')
	fs.writeFileSync(traceFile, '')
	return {
		directory, bin, home, installed, packageDirectory,
		run(script, extraEnv = {}) {
			return spawnSync('/bin/sh', ['./' + script], {
				cwd: directory,
				encoding: 'utf8',
				timeout: 10000,
				env: {
					PATH: `${bin}:/usr/bin:/bin`,
					HOME: home,
					LC_ALL: 'C',
					EVENTCALENDAR_TEST_TRACE: traceFile,
					EVENTCALENDAR_TEST_BRANCH: branchFile,
					...extraEnv,
				},
			})
		},
		trace: () => fs.readFileSync(traceFile, 'utf8'),
		branch: () => fs.readFileSync(branchFile, 'utf8'),
	}
}

function assertSuccess(result) {
	assert.equal(result.status, 0, result.stdout + result.stderr + (result.error || ''))
}

for (const script of ['install', 'update']) {
	test(`${script} keeps Plasma 5 on plasma-5 and installs desktop metadata`, t => {
		const scenario = fixture(t)
		writeExecutable(path.join(scenario.bin, 'jq'), 'echo "jq must not be needed for desktop metadata" >&2\nexit 92\n')
		assertSuccess(scenario.run(script))
		assert.equal(scenario.branch(), 'plasma-5')
		assert.match(scenario.trace(), /git pull --ff-only origin plasma-5/)
		assert.doesNotMatch(scenario.trace(), /git checkout|kpackagetool6/)
		assert.ok(fs.existsSync(path.join(scenario.installed, 'metadata.desktop')))
	})

	test(`${script} switches a master checkout to plasma-5 on Plasma 5`, t => {
		const scenario = fixture(t, { branch: 'master' })
		assertSuccess(scenario.run(script))
		assert.equal(scenario.branch(), 'plasma-5')
		assert.match(scenario.trace(), /git checkout plasma-5/)
		assert.doesNotMatch(scenario.trace(), /git pull --ff-only origin master/)
	})

	test(`${script} selects master and JSON metadata on Plasma 6`, t => {
		const scenario = fixture(t, { major: 6, branch: 'plasma-5' })
		assertSuccess(scenario.run(script))
		assert.equal(scenario.branch(), 'master')
		assert.match(scenario.trace(), /git pull --ff-only origin master/)
		assert.doesNotMatch(scenario.trace(), /git checkout plasma-6|kpackagetool5/)
		assert.ok(fs.existsSync(path.join(scenario.installed, 'metadata.json')))
	})
}

test('install leaves uncommitted repository changes on their current branch', t => {
	const scenario = fixture(t, { branch: 'local-changes' })
	assertSuccess(scenario.run('install', { EVENTCALENDAR_TEST_DIRTY: '1' }))
	assert.equal(scenario.branch(), 'local-changes')
	assert.doesNotMatch(scenario.trace(), /git checkout|git fetch|git pull/)
})

test('update rejects uncommitted repository changes before fetching', t => {
	const scenario = fixture(t, { branch: 'local-changes' })
	assert.notEqual(scenario.run('update', { EVENTCALENDAR_TEST_DIRTY: '1' }).status, 0)
	assert.equal(scenario.branch(), 'local-changes')
	assert.doesNotMatch(scenario.trace(), /git checkout|git fetch|git pull/)
})

test('install prefers desktop metadata when a generated JSON file is present', t => {
	const scenario = fixture(t)
	fs.appendFileSync(path.join(scenario.packageDirectory, 'metadata.desktop'), '[Other Group]\nX-KDE-PluginInfo-Name=../outside\n')
	fs.writeFileSync(path.join(scenario.packageDirectory, 'metadata.json'), JSON.stringify({ KPlugin: { Id: null } }))
	assertSuccess(scenario.run('install'))
	assert.ok(fs.existsSync(path.join(scenario.installed, 'metadata.desktop')))
})

test('install replaces only the validated widget directory', t => {
	const scenario = fixture(t)
	fs.mkdirSync(scenario.installed, { recursive: true })
	fs.writeFileSync(path.join(scenario.installed, 'old.txt'), 'old package')
	const neighbor = path.join(scenario.installed, '../another-widget')
	fs.mkdirSync(neighbor)
	fs.writeFileSync(path.join(neighbor, 'keep.txt'), 'keep')
	assertSuccess(scenario.run('install'))
	assert.ok(!fs.existsSync(path.join(scenario.installed, 'old.txt')))
	assert.equal(fs.readFileSync(path.join(scenario.installed, 'content.txt'), 'utf8'), 'new package')
	assert.equal(fs.readFileSync(path.join(neighbor, 'keep.txt'), 'utf8'), 'keep')
})

for (const metadata of ['desktop', 'json']) {
	test(`uninstall accepts ${metadata} metadata and backs up the package`, t => {
		const scenario = fixture(t, { metadata })
		fs.mkdirSync(scenario.installed, { recursive: true })
		fs.writeFileSync(path.join(scenario.installed, 'old.txt'), 'old package')
		if (metadata === 'desktop') {
			writeExecutable(path.join(scenario.bin, 'jq'), 'exit 92\n')
		}
		assertSuccess(scenario.run('uninstall'))
		assert.ok(!fs.existsSync(scenario.installed))
		assert.match(scenario.trace(), /qdbus org.kde.plasmashell/)
		const backups = path.join(scenario.home, '.local/share/plasma-widget-backups')
		const backup = fs.readdirSync(backups)[0]
		assert.ok(fs.existsSync(path.join(backups, backup, 'package', `metadata.${metadata === 'desktop' ? 'desktop' : 'json'}`)))
	})
}

for (const metadata of ['desktop', 'json', 'missing']) {
	const invalidIds = metadata === 'missing' ? [packageId] : ['', '.', '..', '../outside']
	if (metadata === 'json') invalidIds.push(null)
	for (const id of invalidIds) {
		for (const script of ['install', 'uninstall']) {
			test(`${script} rejects ${metadata} metadata with package ID ${JSON.stringify(id)}`, t => {
				const scenario = fixture(t, { metadata, id: metadata === 'desktop' && id === null ? '' : id })
				fs.mkdirSync(scenario.installed, { recursive: true })
				fs.writeFileSync(path.join(scenario.installed, 'old.txt'), 'old package')
				assert.notEqual(scenario.run(script).status, 0)
				assert.equal(fs.readFileSync(path.join(scenario.installed, 'old.txt'), 'utf8'), 'old package')
				assert.doesNotMatch(scenario.trace(), /qdbus /)
			})
		}
	}
}
