import QtQuick 2.0
import QtTest 1.2

import "../package/contents/ui/lib"
import "../package/contents/ui"

TestCase {
	name: "ExecUtilPlasma5"

	ExecUtil { id: executable }
	NotificationManager { id: notifications }

	function test_notificationManagerLoads() {
		verify(notifications.executable !== null)
		compare(notifications.executable.engine, "executable")
	}

	function test_commandCompletion() {
		var result = null
		executable.exec("printf eventcalendar-plasma5", function(cmd, exitCode, exitStatus, stdout, stderr) {
			result = { exitCode: exitCode, exitStatus: exitStatus, stdout: stdout, stderr: stderr }
		})
		tryVerify(function() { return result !== null }, 5000)
		compare(result.exitCode, 0)
		compare(result.exitStatus, 0)
		compare(result.stdout, "eventcalendar-plasma5")
		compare(result.stderr, "")
	}

	function test_commandFailure() {
		var result = null
		executable.exec("sh -c 'exit 7'", function(cmd, exitCode, exitStatus, stdout, stderr) {
			result = { exitCode: exitCode, exitStatus: exitStatus }
		})
		tryVerify(function() { return result !== null }, 5000)
		compare(result.exitCode, 7)
		compare(result.exitStatus, 0)
	}
}
