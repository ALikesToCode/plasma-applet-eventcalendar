import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents3

Flow {
	id: durationSelector

	property alias startTimeSelector: startTimeSelector
	property alias endTimeSelector: endTimeSelector

	property alias startDateTime: startTimeSelector.dateTime
	property alias endDateTime: endTimeSelector.dateTime

	property bool enabled: true
	property bool showTime: false

	spacing: 0
	// Layout.minimumWidth: startTimeSelector.minimumWidth + seperatorLabel.implicitWidth + endTimeSelector.minimumWidth

	DateTimeSelector {
		id: startTimeSelector
		enabled: durationSelector.enabled
		showTime: durationSelector.showTime
		dateFirst: true

		onDateTimeShifted: {
			logger.debug('onDateTimeShifted')
			logger.debug('    dt1', oldDateTime)
			logger.debug('    dt2', dateTime)
			logger.debug('  delta', deltaDateTime)

			var shiftedEndDate = new Date(endTimeSelector.dateTime.valueOf() + deltaDateTime)
			logger.debug('    t3', shiftedEndDate)
			endTimeSelector.dateTime = shiftedEndDate
		}
	}
	PlasmaComponents3.Label {
		id: seperatorLabel
		text: ' ' + i18n("to") + ' '
		font.weight: Font.Bold
		verticalAlignment: Text.AlignVCenter
		height: startTimeSelector.implicitHeight
	}
	DateTimeSelector {
		id: endTimeSelector
		enabled: durationSelector.enabled
		showTime: durationSelector.showTime
		dateFirst: false
	}
}
