import QtQuick
import org.kde.plasma.components as PlasmaComponents3

import "lib/CalendarSelection.js" as CalendarSelection

PlasmaComponents3.ComboBox {
	id: calendarSelector
	model: [
		{ text: i18n("[No Calendars]") }
	]
	textRole: "text"

	readonly property var selectedCalendar: currentIndex >= 0 ? model[currentIndex] : null
	readonly property var selectedCalendarId: selectedCalendar ? selectedCalendar.calendarId : null
	readonly property bool selectedIsTasklist: {
		if (!selectedCalendar) {
			return false
		}
		return selectedCalendar.isTasklist === true
	}

	function populate(calendarList, initialCalendarId) {
		var choices = CalendarSelection.buildChoices(calendarList, initialCalendarId)
		var list = choices.list
		if (list.length === 0) {
			list.push({
				text: i18n("[No Calendars]"),
				calendarId: "",
				isTasklist: false,
			})
		}
		calendarSelector.model = list
		calendarSelector.currentIndex = choices.selectedIndex
	}
}
