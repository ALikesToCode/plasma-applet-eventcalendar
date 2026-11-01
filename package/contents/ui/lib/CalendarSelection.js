// Choices for the calendar picker in the agenda's new-event form.

// Labels lead with the calendar's own name. The account comes second, so a
// narrow picker still shows which calendar is selected.
function choiceLabel(calendar) {
	var name = calendar.calendarName
	var account = calendar.accountLabel
	if (name && account) {
		// A primary calendar is named after its account by default, so the
		// account is shown once. Other calendars always name their account.
		if (calendar.primary === true && name === account) {
			return name
		}
		return name + " (" + account + ")"
	}
	return calendar.summary
}

// Lists the calendars the user can add to. The remembered calendar comes
// first in priority, then the account's primary calendar, then the first one
// in the list.
function buildChoices(calendarList, initialCalendarId) {
	var list = []
	var selectedIndex = -1
	var primaryIndex = -1
	calendarList.forEach(function(calendar) {
		var canEditCalendar = calendar.accessRole === 'writer' || calendar.accessRole === 'owner'
		var isSelected = !!initialCalendarId && calendar.id === initialCalendarId
		if (!canEditCalendar && !isSelected) {
			return
		}
		if (isSelected && selectedIndex < 0) {
			selectedIndex = list.length
		}
		if (calendar.primary === true && primaryIndex < 0) {
			primaryIndex = list.length
		}
		list.push({
			calendarId: calendar.id,
			text: choiceLabel(calendar),
			backgroundColor: calendar.backgroundColor,
			isTasklist: calendar.isTasklist,
		})
	})
	if (selectedIndex < 0) {
		selectedIndex = primaryIndex >= 0 ? primaryIndex : 0
	}
	return {
		list: list,
		selectedIndex: selectedIndex,
	}
}

if (typeof module !== "undefined") {
	module.exports = {
		choiceLabel: choiceLabel,
		buildChoices: buildChoices,
	}
}
