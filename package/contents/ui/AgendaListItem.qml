import QtQuick 2.0
import QtQuick.Controls 1.1
import QtQuick.Layouts 1.1
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents3

import "Shared.js" as Shared
import "./weather/WeatherApi.js" as WeatherApi

GridLayout {
	id: agendaListItem
	readonly property int agendaItemIndex: index
	columnSpacing: 0
	property var agendaItemEvents: model.events
	property var agendaItemTasks: model.tasks
	property date agendaItemDate: model.date
	property bool agendaItemIsToday: false
	function checkIfToday() {
		agendaItemIsToday = timeModel.currentTime && model.date ? Shared.isSameDate(timeModel.currentTime, model.date) : false
		// console.log('checkIfToday()', agendaListItem.agendaItemIsToday, timeModel.currentTime, model.date)
	}
	Component.onCompleted: agendaListItem.checkIfToday()
	Connections {
		target: timeModel
		function onLoaded() {
			agendaListItem.checkIfToday()
		}
		function onDateChanged() {
			agendaListItem.checkIfToday()
		}
	}
	property bool agendaItemInProgress: agendaItemIsToday
	property bool weatherOnRight: plasmoid.configuration.agendaWeatherOnRight
	property alias tasksRepeater: tasksRepeater
	property alias eventsRepeater: eventsRepeater

	Connections {
		target: agendaModel
		function onPopulatingChanged() {
			if (!agendaModel.populating) {
				agendaListItem.reset()
			}
		}
	}
	function reset() {
		newEventForm.active = false
		agendaListItem.checkIfToday()
	}
	function openWeatherForecast() {
		WeatherApi.openCityUrl(plasmoid.configuration)
	}
	function toggleNewEventForm() {
		newEventForm.active = !newEventForm.active
	}
	function fullDateLabel() {
		return Qt.formatDateTime(agendaItemDate, Locale.LongFormat)
	}
	function weatherAccessibleName() {
		return i18n("Weather forecast for %1", fullDateLabel())
	}
	function dateAccessibleDescription() {
		return i18n("Press to add a new event on %1", fullDateLabel())
	}

	// readonly property int itemOffset: agendaScrollView.getItemOffsetY(index)
	// readonly property int scrollOffset: agendaScrollView.scrollY - itemOffset
	// readonly property bool isCurrentItem: 0 <= scrollOffset && scrollOffset < height
	// onItemOffsetChanged: console.log(index, 'itemOffset', itemOffset)

	LinkRect {
		id: weatherLink
		visible: agendaModel.showDailyWeather
		Layout.alignment: Qt.AlignTop
		Layout.column: weatherOnRight ? 2 : 0
		Layout.minimumWidth: appletConfig.agendaDateColumnWidth
		implicitWidth: itemWeatherColumn.implicitWidth
		onWidthChanged: {
			if (width > appletConfig.agendaDateColumnWidth) {
				appletConfig.agendaDateColumnWidth = width
			}
		}
		implicitHeight: itemWeatherColumn.implicitHeight
		activeFocusOnTab: visible && enabled
		Accessible.role: Accessible.Button
		Accessible.name: weatherAccessibleName()
		Accessible.description: i18n("Press to open the weather forecast in your browser")
		Accessible.focusable: activeFocusOnTab
		Accessible.focused: activeFocus
		Accessible.onPressAction: openWeatherForecast()
		Keys.onReturnPressed: function(event) {
			openWeatherForecast()
			event.accepted = true
		}
		Keys.onEnterPressed: function(event) {
			openWeatherForecast()
			event.accepted = true
		}
		Keys.onSpacePressed: function(event) {
			openWeatherForecast()
			event.accepted = true
		}

		// readonly property int maxOffset: agendaListItem.height - height
		// Layout.topMargin: agendaListItem.isCurrentItem ? Math.min(maxOffset, agendaListItem.scrollOffset) : 0

		ColumnLayout {
			id: itemWeatherColumn
			Layout.alignment: Qt.AlignTop
			spacing: 0
			anchors.horizontalCenter: parent.horizontalCenter

			FontIcon {
				visible: showWeather && plasmoid.configuration.agendaWeatherShowIcon
				color: agendaItemIsToday ? inProgressColor : PlasmaCore.ColorScope.textColor
				source: weatherIcon
				height: appletConfig.agendaWeatherIconSize
				showOutline: plasmoid.configuration.showOutlines
				Layout.fillWidth: true
			}

			PlasmaComponents3.Label {
				id: itemWeatherText
				visible: showWeather && plasmoid.configuration.agendaWeatherShowText
				text: weatherText
				color: agendaItemIsToday ? inProgressColor : PlasmaCore.ColorScope.textColor
				opacity: agendaItemIsToday ? 1 : 0.75
				font.pointSize: -1
				font.pixelSize: appletConfig.agendaFontSize
				font.weight: agendaItemIsToday ? inProgressFontWeight : Font.Normal
				Layout.alignment: Qt.AlignHCenter
			}

			PlasmaComponents3.Label {
				id: itemWeatherTemps
				visible: showWeather
				text: {
					var high = isNaN(model.tempHigh) ? '?' : model.tempHigh + '°'
					var low = isNaN(model.tempLow) ? '?' : model.tempLow + '°'
					return high + ' | ' + low
				}
				color: agendaItemIsToday ? inProgressColor : PlasmaCore.ColorScope.textColor
				opacity: agendaItemIsToday ? 1 : 0.75
				font.pointSize: -1
				font.pixelSize: appletConfig.agendaFontSize
				font.weight: agendaItemIsToday ? inProgressFontWeight : Font.Normal
				Layout.alignment: Qt.AlignHCenter
			}
		}

		tooltipMainText: weatherDescription
		tooltipSubText: weatherNotes

		onLeftClicked: {
			openWeatherForecast()
		}
	}

	LinkRect {
		id: dateLink
		Layout.alignment: Qt.AlignTop
		Layout.column: weatherOnRight ? 0 : 1
		implicitWidth: appletConfig.agendaDateColumnWidth
		activeFocusOnTab: enabled
		Accessible.role: Accessible.Button
		Accessible.name: fullDateLabel()
		Accessible.description: dateAccessibleDescription()
		Accessible.focusable: activeFocusOnTab
		Accessible.focused: activeFocus
		Accessible.onPressAction: toggleNewEventForm()
		Keys.onReturnPressed: function(event) {
			toggleNewEventForm()
			event.accepted = true
		}
		Keys.onEnterPressed: function(event) {
			toggleNewEventForm()
			event.accepted = true
		}
		Keys.onSpacePressed: function(event) {
			toggleNewEventForm()
			event.accepted = true
		}

		// readonly property int maxOffset: agendaListItem.height - height
		// Layout.topMargin: agendaListItem.isCurrentItem ? Math.min(maxOffset, agendaListItem.scrollOffset) : 0

		ColumnLayout {
			id: itemDateColumn
			anchors.left: parent.left
			anchors.right: parent.right
			anchors.leftMargin: appletConfig.agendaColumnSpacing
			anchors.rightMargin: appletConfig.agendaColumnSpacing
			spacing: 0

			PlasmaComponents3.Label {
				id: itemDate
				text: Qt.formatDateTime(date, i18nc("agenda date format line 1", "MMM d"))
				color: agendaItemIsToday ? inProgressColor : PlasmaCore.ColorScope.textColor
				opacity: agendaItemIsToday ? 1 : 0.75
				font.pointSize: -1
				font.pixelSize: appletConfig.agendaFontSize
				font.weight: agendaItemIsToday ? inProgressFontWeight : Font.Normal
				Layout.fillWidth: true
				horizontalAlignment: Text.AlignRight
			}

			PlasmaComponents3.Label {
				id: itemDay
				text: Qt.formatDateTime(date, i18nc("agenda date format line 2", "ddd"))
				color: agendaItemIsToday ? inProgressColor : PlasmaCore.ColorScope.textColor
				opacity: agendaItemIsToday ? 1 : 0.5
				font.pointSize: -1
				font.pixelSize: appletConfig.agendaFontSize
				font.weight: agendaItemIsToday ? inProgressFontWeight : Font.Normal
				Layout.fillWidth: true
				horizontalAlignment: Text.AlignRight
			}
		}

		onLeftClicked: {
			if (false) {
				// agenda_date_clicked == "browser_newevent"
				Shared.openGoogleCalendarNewEventUrl(date)
			} else if (true) {
				// agenda_date_clicked == "agenda_newevent"
				toggleNewEventForm()
			}
		}
	}

	ColumnLayout {
		Layout.alignment: Qt.AlignTop | Qt.AlignLeft
		Layout.column: weatherOnRight ? 1 : 2
		spacing: appletConfig.agendaEventSpacing

		NewEventForm {
			id: newEventForm
			Layout.fillWidth: true
		}

		ColumnLayout {
			id: eventsLayout
			spacing: appletConfig.agendaEventSpacing
			Layout.fillWidth: true

			Repeater {
				id: eventsRepeater
				model: agendaItemEvents

				delegate: AgendaEventItem {
					id: agendaEventItem
					width: parent.width
				}
			}

			Repeater {
				id: tasksRepeater
				model: agendaItemTasks

				delegate: AgendaTaskItem {
					id: agendaTaskItem
					width: parent.width
				}
			}
		}

	}

	function indexOfEvent(eventId) {
		for (var i = 0; i < eventsRepeater.model.length; i++) {
			var event = eventsRepeater.model[i]
			if (event.id === eventId) {
				return i
			}
		}
		for (var i = 0; i < tasksRepeater.model.length; i++) {
			var task = tasksRepeater.model[i]
			if (task.id === eventId) {
				return eventsRepeater.model.length + i
			}
		}
		return -1
	}

	function getEventOffset(index) {
		var yOffset = newEventForm.height
		for (var i = 0; i < index && i < eventsRepeater.count; i++) {
			var item = eventsRepeater.itemAt(i)
			if (i > 0) {
				yOffset += eventsLayout.spacing
			}
			yOffset += item.height
		}
		for (var i = 0; i < tasksRepeater.count; i++) {
			var item = tasksRepeater.itemAt(i)
			var eventIndex = eventsRepeater.count + i
			if (eventIndex >= index) {
				break
			}
			if (i > 0 || eventsRepeater.count > 0) {
				yOffset += eventsLayout.spacing
			}
			yOffset += item.height
		}
		return yOffset
	}
}
