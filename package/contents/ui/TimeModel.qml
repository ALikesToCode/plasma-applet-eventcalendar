import QtQuick
import QtQuick.Layouts
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as Plasma5Support

Item {
	id: timeModel
	property var currentTime: new Date()
	property alias dataSource: dataSource
	property var allTimezones: {
		var timezones = plasmoid.configuration.selectedTimeZones.toString()
		if (timezones.length > 0) {
			timezones = timezones.split(',')
		} else {
			timezones = []
		}
		if (timezones.indexOf('Local') === -1) {
			timezones.push('Local')
		}
		return timezones
	}

	signal secondChanged()
	signal minuteChanged()
	signal dateChanged()
	signal loaded()

	// Only the tooltip reads this, for the other time zones, which it shows
	// without seconds.
	Plasma5Support.DataSource {
		id: dataSource
		engine: "time"
		connectedSources: timeModel.allTimezones
		interval: 60000
		intervalAlignment: Plasma5Support.Types.AlignToMinute
	}

	// A fixed 1000ms interval keeps the phase it started with, so the seconds
	// could lag the system clock by up to a second. Re-aim each tick at the
	// start of the next second instead.
	Timer {
		id: secondTimer
		running: !timeModel.testing
		repeat: true
		triggeredOnStart: true
		interval: 1000
		onTriggered: timeModel.updateCurrentTime()
	}

	function updateCurrentTime() {
		var now = new Date()
		secondTimer.interval = Math.max(5, 1000 - now.getMilliseconds())
		// Qt's coarse timers can fire up to 5% early, which lands just before
		// the boundary. If this second is already shown, only re-aim.
		if (ready && Math.floor(now.getTime() / 1000) === Math.floor(currentTime.getTime() / 1000)) {
			return
		}
		currentTime = now
		tick()
	}

	property bool ready: false
	property int lastMinute: -1
	property int lastDate: -1
	function tick() {
		if (!ready) {
			ready = true
			loaded()
		}
		secondChanged()
		var currentMinute = currentTime.getMinutes()
		if (currentMinute != lastMinute) {
			minuteChanged()
			var currentDate = currentTime.getDate()
			if (currentDate != lastDate) {
				dateChanged()
				lastDate = currentDate
			}
			lastMinute = currentMinute
		}
	}


	property bool testing: false
	Component.onCompleted: {
		if (testing) {
			currentTime = new Date(2016, 1, 2, 23, 59, 55)
			timeModel.loaded()
		}
	}

	Timer {
		running: testing
		repeat: true
		interval: 1000
		onTriggered: {
			currentTime.setSeconds(currentTime.getSeconds() + 1)
			timeModel.currentTimeChanged()
			timeModel.tick()
		}
	}
}
