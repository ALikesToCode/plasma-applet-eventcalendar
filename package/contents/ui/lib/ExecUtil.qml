// Version 6

import QtQuick
import org.kde.plasma.plasma5support as Plasma5Support

Plasma5Support.DataSource {
	id: executable
	engine: "executable"
	connectedSources: []
	onNewData: function(sourceName, data) {
		var cmd = sourceName
		var exitCode = data["exit code"]
		var exitStatus = data["exit status"]
		var stdout = data["stdout"]
		var stderr = data["stderr"]
		var listener = listeners[cmd]
		if (listener) {
			listener(cmd, exitCode, exitStatus, stdout, stderr)
		}
		exited(cmd, exitCode, exitStatus, stdout, stderr)
		disconnectSource(sourceName) // cmd finished
	}

	signal exited(string cmd, int exitCode, int exitStatus, string stdout, string stderr)

	function trimOutput(stdout) {
		return stdout.replace(/\n/g, ' ').trim()
	}

	property var listeners: ({}) // Empty Map
	property string argvRunnerPath: {
		var resolved = String(Qt.resolvedUrl("../../scripts/run_argv.py"))
		return resolved.indexOf("file://") === 0 ? resolved.slice(7) : resolved
	}

	// Note that this has not gone under a security audit.
	// You probably shouldn't trust 3rd party input.
	function wrapToken(token) {
		token = "" + token
		// ' => '"'"' to escape the single quotes
		token = token.replace(/\'/g, "\'\"\'\"\'")
		token = "\'" + token + "\'"
		return token
	}

	// Note that this has not gone under a security audit.
	// You probably shouldn't trust 3rd party input.
	// Some of these might be unnecessary.
	function sanitizeString(str) {
		// Remove NULL (0x00), Ctrl+C (0x03), Ctrl+D (0x04) block of characters
		// Remove quotes ("" and '')
		// Remove DEL
		return str.replace(/[\x00-\x1F\'\"\x7F]/g, '')
	}

	function stripQuotes(str) {
		return str.replace(/[\'\"]/g, '')
	}

	function encodeArgvPayload(argv) {
		var payload = Qt.btoa(JSON.stringify(argv))
		payload = payload.replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/g, '')
		return payload
	}

	function buildArgvCommand(argv) {
		return [
			"python3",
			argvRunnerPath,
			encodeArgvPayload(argv),
		].map(wrapToken).join(" ")
	}

	function isSensitiveArgFlag(arg) {
		var lower = ("" + arg).toLowerCase()
		return [
			"--access-token",
			"--access_token",
			"--refresh-token",
			"--refresh_token",
			"--client-secret",
			"--client_secret",
			"--password",
			"--passwd",
			"--authorization",
			"--cookie",
		].indexOf(lower) >= 0
	}

	function isSensitiveArgValue(arg) {
		var lower = ("" + arg).toLowerCase()
		return lower.indexOf("authorization:") === 0
			|| lower.indexOf("cookie:") === 0
			|| lower.indexOf("bearer ") === 0
	}

	function containsSensitiveArgv(argv) {
		for (var i = 0; i < argv.length; i++) {
			if (isSensitiveArgFlag(argv[i])) {
				return true
			}
			if (i > 0 && isSensitiveArgFlag(argv[i - 1])) {
				return true
			}
			if (isSensitiveArgValue(argv[i])) {
				return true
			}
		}
		return false
	}

	function failImmediately(cmd, callback, message) {
		console.error(message)
		if (typeof callback === "function") {
			callback(Array.isArray(cmd) ? JSON.stringify(cmd) : String(cmd), 1, 1, "", message)
		}
	}

	function runCommand(cmd, callback) {
		if (typeof callback === 'function') {
			if (listeners[cmd]) { // Our implementation only allows 1 callback per command.
				exited.disconnect(listeners[cmd])
				delete listeners[cmd]
			}
			var listener = execCallback.bind(executable, callback)
			listeners[cmd] = listener
		}
		// console.log('cmd', cmd)
		connectSource(cmd)
	}

	function exec(cmd, callback) {
		if (Array.isArray(cmd)) {
			failImmediately(cmd, callback, "ExecUtil.exec() only accepts string commands. Use execArgv() for non-secret argv values.")
			return
		}
		runCommand(cmd, callback)
	}

	function execArgv(argv, callback) {
		if (!Array.isArray(argv) || !argv.length) {
			failImmediately(argv, callback, "ExecUtil.execArgv() requires a non-empty argv array.")
			return
		}
		if (containsSensitiveArgv(argv)) {
			failImmediately(argv, callback, "ExecUtil.execArgv() must not be used with secrets or authorization headers.")
			return
		}
		runCommand(buildArgvCommand(argv), callback)
	}

	function execCallback(callback, cmd, exitCode, exitStatus, stdout, stderr) {
		delete listeners[cmd]
		callback(cmd, exitCode, exitStatus, stdout, stderr)
	}

	//--- Tests
	function test() {
		execArgv(['notify-send', 'test', '$(notify-send escape1)'])
		execArgv(['notify-send', 'test', '`notify-send escape2`'])
		execArgv(['notify-send', 'test', '\'; notify-send escape3;\''])
		execArgv(['notify-send', 'test', '\\\'; notify-send escape4;\\\''])
	}
	// Component.onCompleted: test()
}
