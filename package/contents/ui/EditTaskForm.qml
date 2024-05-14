import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.15 as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents3

import "Shared.js" as Shared

Loader {
    id: editTaskForm
    active: false
    visible: active
    Layout.fillWidth: true
    sourceComponent: Component {
        MouseArea {
            id: editTaskItem

            onClicked: focus = true

            implicitWidth: editTaskGrid.implicitWidth
            implicitHeight: editTaskGrid.implicitHeight

            readonly property var task: tasks.get(index)

            Component.onCompleted: {
                agendaScrollView.positionViewAtTask(agendaItemIndex, taskItemIndex)
                editSummaryTextField.forceActiveFocus()

                logger.debugJSON('EditTaskForm.task', task)
            }

            function isEmpty(s) {
                return typeof s === "undefined" || s === null || s === ""
            }
            function hasChanged(a, b) {
                return a != b && !(isEmpty(a) && isEmpty(b))
            }
            function populateIfChanged(args, propKey, newValue) {
                var changed = hasChanged(task[propKey], newValue)
                if (changed) {
                    args[propKey] = newValue
                }
            }
            function getChanges() {
                var args = {}
                populateIfChanged(args, 'title', editSummaryTextField.text)
                populateIfChanged(args, 'notes', editDescriptionTextField.text)
                populateIfChanged(args, 'due', dueTimeSelector.getDueDate())
                return args
            }
            function submit() {
                if (task.calendarId != calendarSelector.selectedCalendarId) {
                    // TODO: Move task
                    // TODO: Call setProperties after moving or vice versa.
                    // https://developers.google.com/tasks/v1/reference/tasks/move
                }

                var args = getChanges()
                eventModel.setEventProperties(task.calendarId, task.id, args)
            }

            function cancel() {
                editTaskForm.active = false
            }

            GridLayout {
                id: editTaskGrid
                anchors.left: parent.left
                anchors.right: parent.right
                columns: 2

                PlasmaComponents3.CheckBox {
                    id: taskCheckBox
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                    checked: task && task.isCompleted
                    enabled: false
                }
                PlasmaComponents3.TextField {
                    id: editSummaryTextField
                    Layout.fillWidth: true
                    placeholderText: i18n("Event Title")
                    text: task && task.title || ""
                    onAccepted: {
                        editTaskItem.submit()
                    }

                    Keys.onEscapePressed: editTaskItem.cancel()
                }

                EventPropertyIcon {
                    source: "x-shape-text"
                    Layout.fillHeight: false
                    Layout.alignment: Qt.AlignTop
                }
                PlasmaComponents3.TextArea {
                    id: editDescriptionTextField
                    placeholderText: i18n("Add description")
                    text: (task && task.notes) || ""

                    Layout.fillWidth: true
                    Layout.preferredHeight: contentHeight + (20 * units.devicePixelRatio)

                    Keys.onEscapePressed: editTaskItem.cancel()

                    Keys.onEnterPressed: _onEnterPressed(event)
                    Keys.onReturnPressed: _onEnterPressed(event)
                    function _onEnterPressed(event) {
                        if ((event.modifiers & Qt.ShiftModifier) || (event.modifiers & Qt.ControlModifier)) {
                            editTaskItem.submit()
                        } else {
                            event.accepted = false
                        }
                    }
                }

                EventPropertyIcon {
                    source: "view-list-symbolic"
                }
                CalendarSelector {
                    id: calendarSelector
                    Layout.fillWidth: true
                    enabled: false
                    Component.onCompleted: {
                        var calendarList = eventModel.getCalendarList()
                        calendarSelector.populate(calendarList, task.calendarId)
                    }
                }

                EventPropertyIcon {
                    source: "view-calendar-upcoming-events"
                }
                RowLayout {
                    DateTimeSelector {
                        id: dueTimeSelector
                        property bool hasDueDate: task && task.dueDateTime
                        visible: hasDueDate
                        showTime: false // Google Tasks API doesn't provide the Time
                        dateTime: {
                            if (task && task.dueDateTime) {
                                return task.dueDateTime
                            } else {
                                return new Date()
                            }
                        }
                        function getDueDate() {
                            if (dueTimeSelector.hasDueDate) {
                                return Shared.dateString(dateTime) + 'T00:00:00.000Z'
                            } else {
                                return null
                            }
                        }
                    }
                    PlasmaComponents3.Button {
                        visible: dueTimeSelector.hasDueDate
                        icon.name: 'edit-delete'
                        onClicked: dueTimeSelector.hasDueDate = false
                    }
                    PlasmaComponents3.Button {
                        visible: !dueTimeSelector.hasDueDate
                        text: i18n("Add due date")
                        onClicked: dueTimeSelector.hasDueDate = true
                    }
                }

                RowLayout {
                    Layout.columnSpan: 2
                    spacing: 4 * units.devicePixelRatio
                    Item {
                        Layout.fillWidth: true
                    }
                    PlasmaComponents3.Button {
                        icon.name: "document-save"
                        text: i18n("&Save")
                        onClicked: editTaskItem.submit()
                    }
                    PlasmaComponents3.Button {
                        icon.name: "dialog-cancel"
                        text: i18n("&Cancel")
                        onClicked: editTaskItem.cancel()
                    }
                }
            }
        }
    }
}
