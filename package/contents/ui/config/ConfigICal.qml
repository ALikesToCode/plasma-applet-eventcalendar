import QtQuick 2.0
import QtQuick.Controls 1.0
import QtQuick.Controls.Styles 1.1
import QtQuick.Dialogs 1.2
import QtQuick.Layouts 1.0
import org.kde.kirigami 2.0 as Kirigami

import org.kde.kcoreaddons 1.0 as KCoreAddons

import ".."
import "../lib"

ConfigPage {
	id: page

	KCoreAddons.KUser {
		id: kuser
	}

	readonly property string localCalendarDir: '/home/' + kuser.loginName + '/.local/share/plasma_org.kde.plasma.eventcalendar'

	function normalizeLocalPath(value) {
		var path = String(value || "").trim()
		if (path.indexOf("file://") === 0) {
			path = path.slice(7)
		}
		return path
	}

	function isAllowedCalendarUrl(value) {
		var trimmed = String(value || "").trim()
		if (!trimmed) {
			return true
		}
		if (/^https?:\/\/\S+$/i.test(trimmed)) {
			return true
		}
		var path = normalizeLocalPath(trimmed)
		return path.indexOf(localCalendarDir + "/") === 0 && /\.ics$/i.test(path)
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
			var icsPath = localCalendarDir + '/calendar.ics'
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
			iconName: "resource-calendar-insert"
			text: i18n("Add Calendar")
			onClicked: calendarsModel.addCalendar()
		}
		Button {
			iconName: "resource-calendar-insert"
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
					style: CheckBoxStyle {}

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
							iconName: "trash-empty"
							onClicked: calendarsModel.removeIndex(index)
						}
					}
					RowLayout {
						TextField {
							id: calendarUrlField
							Layout.fillWidth: true
							text: model.url
							placeholderText: i18n("https:// URL or local %1/*.ics file", localCalendarDir)
							onTextChanged: {
								if (isAllowedCalendarUrl(text)) {
									calendarsModel.setItemProperty(index, 'url', text.trim())
								}
							}
						}

						Button {
							iconName: "folder-open"
							text: i18n("Browse")
							onClicked: {
								filePicker.open()
							}

							FileDialog {
								id: filePicker

								nameFilters: [ i18n("iCalendar (*.ics)") ]
								folder: "file://" + localCalendarDir

								onFileUrlChanged: {
									if (isAllowedCalendarUrl(fileUrl)) {
										calendarUrlField.text = fileUrl
									}
								}
							}
						}
					}
				}
			}
		}
	}
}
