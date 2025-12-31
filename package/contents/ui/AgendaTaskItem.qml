import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3

import "LocaleFuncs.js" as LocaleFuncs
import "Shared.js" as Shared

LinkRect {
	id: agendaTaskItem
	readonly property int taskItemIndex: index
	Layout.fillWidth: true
	implicitHeight: contents.implicitHeight

	property bool taskIsOverdue: false
	function checkIfIsOverdue() {
		if (model.due) {
			taskIsOverdue = !model.isCompleted && model.dueEndTime < timeModel.currentTime
		} else {
			taskIsOverdue = false
		}
	}
	Connections {
		target: timeModel
		function onLoaded() {
			agendaTaskItem.checkIfIsOverdue()
		}
		function onMinuteChanged() {
			agendaTaskItem.checkIfIsOverdue()
		}
	}
	Component.onCompleted: {
		agendaTaskItem.checkIfIsOverdue()
	}

	property alias isEditing: editTaskForm.active
	enabled: !isEditing

	readonly property string eventTimestamp: {
		if (model.due) {
			var dueDateTime = model.dueDateTime
			if (!Shared.isValidDate(dueDateTime)) {
				dueDateTime = new Date(dueDateTime)
			}
			if (!Shared.isValidDate(dueDateTime)) {
				return ''
			}
			if (model.due.indexOf('T00:00:00.000Z') !== -1) {
				// Due at end of day
				var shortDateFormat = i18nc("short month+date format", "MMM d")
				return Qt.formatDateTime(dueDateTime, shortDateFormat)
			} else {
				// Due at specific time
				return LocaleFuncs.formatEventDateTime(dueDateTime, {
					clock24h: appletConfig.clock24h,
				})
			}
		} else {
			return ''
		}
	}


	//---
	RowLayout {
		id: contents
		anchors.left: parent.left
		anchors.right: parent.right
		spacing: 4 * Screen.devicePixelRatio

		PlasmaComponents3.CheckBox {
			id: taskCheckBox
			Layout.alignment: Qt.AlignTop
			visible: !editTaskForm.visible
			checked: model.isCompleted

			onToggled: {
				var task = tasks.get(taskItemIndex)
				var args = {
					status: checked ? 'completed' : 'needsAction'
				}
				eventModel.setEventProperties(task.calendarId, task.id, args)
			}
		}

		ColumnLayout {
			id: taskColumn
			Layout.alignment: Qt.AlignTop
			Layout.fillWidth: true
			spacing: 0

			PlasmaComponents3.Label {
				id: taskTitle
				text: model.title
				color: Kirigami.Theme.textColor
				font.pointSize: -1
				font.pixelSize: appletConfig.agendaFontSize
				visible: !editTaskForm.visible
				Layout.fillWidth: true

				// The Following doesn't seem to be applicable anymore (left comment just in case).
				// Wrapping causes reflow, which causes scroll to selection to miss the selected date
				// since it reflows after updateUI/scrollToDate is done.
				wrapMode: Text.Wrap
			}

			RowLayout {
				id: taskDue
				readonly property bool showProperty: !!model.due
				visible: showProperty && !editTaskForm.visible
				spacing: Kirigami.Units.smallSpacing

				Kirigami.Icon {
					source: "view-task"
					Layout.preferredHeight: taskDueLabel.implicitHeight
					Layout.preferredWidth: taskDueLabel.implicitHeight
				}
				PlasmaComponents3.Label {
					id: taskDueLabel
					text: eventTimestamp
					color: taskIsOverdue ? isOverdueColor : Kirigami.Theme.textColor
					opacity: taskIsOverdue ? 1 : 0.75
					font.pointSize: -1
					font.pixelSize: appletConfig.agendaFontSize
					font.weight: taskIsOverdue ? isOverdueFontWeight : Font.Normal
				}
			}

			Item {
				id: taskNoteSpacing
				visible: taskNotes.visible
				implicitHeight: 4 * Screen.devicePixelRatio
			}

			PlasmaComponents3.Label {
				id: taskNotes
				readonly property bool showProperty: plasmoid.configuration.agendaShowEventDescription && text
				visible: showProperty && !editTaskForm.visible
				text: Shared.renderText(model.notes)
				color: Kirigami.Theme.textColor
				opacity: 0.75
				font.pointSize: -1
				font.pixelSize: appletConfig.agendaFontSize
				Layout.fillWidth: true
				wrapMode: Text.Wrap // See warning at taskTitle.wrapMode

					linkColor: Kirigami.Theme.highlightColor
					onLinkActivated: function(link) {
						Qt.openUrlExternally(link)
					}
					MouseArea {
					anchors.fill: parent
					acceptedButtons: Qt.NoButton // we don't want to eat clicks on the Text
					cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
				}
			}

			Item {
				id: taskEditorSpacing
				visible: editTaskForm.visible
				implicitHeight: 4 * Screen.devicePixelRatio
			}

			EditTaskForm {
				id: editTaskForm
				Layout.fillWidth: true
				// active: true
			}

		} // taskColumn

		// PlasmaComponents3.ToolButton {
		// 	id: openInBrowserButton
		// 	Layout.alignment: Qt.AlignTop
		// 	icon.name: "zoom-in" // Breeze icon looks like "open link iocn"
		// 	onClicked: Qt.openUrlExternally(model.htmlLink)
		// }
	}
	
	onLeftClicked: {
		var task = tasks.get(taskItemIndex)
		logger.logJSON("task", task)
		// var tasklist = eventModel.getTasklist(task.tasklistId)
		// logger.logJSON("tasklist", tasklist)

		// eventModel.toggleCompleted(event.tasklistId, task.id)
	}

	onLoadContextMenu: {
		var menuItem
		var task = tasks.get(taskItemIndex)

		menuItem = contextMenu.newMenuItem()
		menuItem.text = i18n("Edit")
		menuItem.icon.name = "edit-rename"
		menuItem.enabled = task.canEdit
		menuItem.clicked.connect(function() {
			editTaskForm.active = !editTaskForm.active
			agendaScrollView.positionViewAtTask(agendaItemIndex, taskItemIndex)
		})
		contextMenu.addMenuItem(menuItem)

		var deleteMenu = contextMenu.newSubMenu()
		deleteMenu.title = i18n("Delete Event")
		deleteMenu.icon.name = "delete"
		menuItem = deleteMenu.newMenuItem()
		menuItem.text = i18n("Confirm Deletion")
		menuItem.icon.name = "delete"
		menuItem.enabled = task.canEdit
		menuItem.clicked.connect(function() {
			logger.debug('eventModel.deleteTask', task.calendarId, task.id)
			eventModel.deleteEvent(task.calendarId, task.id)
		})
		// deleteMenu.enabled = task.canEdit
		deleteMenu.addMenuItem(menuItem)

		menuItem = contextMenu.newMenuItem()
		menuItem.text = i18n("Edit in browser")
		menuItem.icon.name = "internet-web-browser"
		menuItem.enabled = !!task.htmlLink
		menuItem.clicked.connect(function() {
			Qt.openUrlExternally(task.htmlLink)
		})
		contextMenu.addMenuItem(menuItem)
	}
}
