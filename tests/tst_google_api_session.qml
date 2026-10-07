import QtQuick 2.0
import QtTest 1.2

import "../package/contents/ui/calendars"

TestCase {
	name: "GoogleApiSessionPlasma5"

	property var plasmoid: ({
		configuration: { accessToken: "" },
		file: function(type, filename) { return filename },
	})

	GoogleApiSession { id: session }

	function test_componentLoads() {
		verify(session.executable !== null)
		compare(session.executable.engine, "executable")
		compare(session.accessToken, "")
	}
}
