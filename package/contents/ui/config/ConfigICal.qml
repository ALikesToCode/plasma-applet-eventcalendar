import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

import org.kde.coreaddons as KCoreAddons

import ".."
import "../lib"

ConfigPage {
	id: page

	KCoreAddons.KUser {
		id: kuser
	}

	Base64JsonListModel {
		id: calendarsModel
		configKey: 'icalCalendarList'

		function addCalendar() {
			addItem({
				url: '',
				name: 'Label',
				backgroundColor: '' + Kirigami.Theme.highlightColor,
				show: true,
				isReadOnly: true,
			})
		}

		function addNewCalendar() {
			var dirPath = '/home/' + kuser.loginName + '/.local/share/plasma_org.kde.plasma.eventcalendar'
			var icsPath = dirPath + '/calendar.ics'
			addItem({
				url: icsPath,
				name: 'Label',
				backgroundColor: '' + Kirigami.Theme.highlightColor,
				show: true,
				isReadOnly: true,
			})
		}
	}

	RowLayout {
		HeaderText {
			text: i18n("Calendars")
		}
		Button {
			icon.name: "resource-calendar-insert"
			text: i18n("Add Calendar")
			onClicked: calendarsModel.addCalendar()
		}
		Button {
			icon.name: "resource-calendar-insert"
			text: i18n("New Calendar")
			onClicked: calendarsModel.addNewCalendar()
		}
	}

	ColumnLayout {
		Layout.fillWidth: true
		spacing: 20 * Kirigami.Units.devicePixelRatio // x4 the default spacing (5px)

		Repeater {
			model: calendarsModel
			delegate: RowLayout {
				spacing: 0

				CheckBox {
					Layout.preferredHeight: labelTextField.height
					Layout.preferredWidth: height
					Layout.alignment: Qt.AlignTop
					checked: show

					onClicked: {
						calendarsModel.setProperty(index, 'show', checked)
					}
				}
				ColumnLayout {
					RowLayout {
						Rectangle {
							Layout.preferredHeight: labelTextField.height
							Layout.preferredWidth: height
							color: model.backgroundColor
						}
						TextField {
							id: labelTextField
							Layout.fillWidth: true
							text: model.name
							placeholderText: i18n("Calendar Label")
						}
						Button {
							icon.name: "trash-empty"
							onClicked: calendarsModel.removeIndex(index)
						}
					}
					RowLayout {
						TextField {
							id: calendarUrlField
							Layout.fillWidth: true
							text: model.url
							onTextChanged: calendarsModel.setItemProperty(index, 'url', text)
						}

						Button {
							icon.name: "folder-open"
							text: i18n("Browse")
							onClicked: {
								filePicker.open()
							}

							FileDialog {
								id: filePicker
								parent: page

								nameFilters: [ i18n("iCalendar (*.ics)") ]

								onAccepted: calendarUrlField.text = selectedFile.toString()
							}
						}
					}
				}
			}
		}
	}
}
