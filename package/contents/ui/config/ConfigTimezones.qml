import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami
import org.kde.plasma.private.digitalclock as DigitalClock

import ".."
import "../lib"

// Mostly copied from digitalclock
KCM.SimpleKCM {
	id: page

	function digitalclock_i18n(message) {
		return i18nd("plasma_applet_org.kde.plasma.digitalclock", message)
	}

	property int cityColumnWidth: Kirigami.Units.gridUnit * 10
	property int regionColumnWidth: Kirigami.Units.gridUnit * 10
	property int tooltipColumnWidth: Kirigami.Units.gridUnit * 6

	DigitalClock.TimeZoneModel {
		id: timeZoneModel

		selectedTimeZones: plasmoid.configuration.selectedTimeZones
		onSelectedTimeZonesChanged: plasmoid.configuration.selectedTimeZones = selectedTimeZones
	}

	MessageWidget {
		id: messageWidget
	}

	ColumnLayout {
		Layout.fillWidth: true
		Layout.fillHeight: true
		spacing: Kirigami.Units.smallSpacing

		TextField {
			id: filter
			Layout.fillWidth: true
			placeholderText: digitalclock_i18n("Search Time Zones")
		}

		RowLayout {
			Layout.fillWidth: true
			spacing: Kirigami.Units.smallSpacing

			Label {
				text: digitalclock_i18n("City")
				font.bold: true
				Layout.preferredWidth: page.cityColumnWidth
			}
			Label {
				text: digitalclock_i18n("Region")
				font.bold: true
				Layout.preferredWidth: page.regionColumnWidth
			}
			Label {
				text: digitalclock_i18n("Comment")
				font.bold: true
				Layout.fillWidth: true
			}
			Label {
				text: i18n("Tooltip")
				font.bold: true
				Layout.preferredWidth: page.tooltipColumnWidth
				horizontalAlignment: Text.AlignHCenter
			}
		}

		ListView {
			id: timeZoneView
			Layout.fillWidth: true
			Layout.fillHeight: true
			clip: true
			focus: true
			highlightFollowsCurrentItem: true
			highlight: Rectangle {
				color: Kirigami.Theme.highlightColor
				opacity: 0.15
			}

			Keys.onSpacePressed: {
				if (timeZoneView.currentItem && timeZoneView.currentItem.toggleChecked) {
					timeZoneView.currentItem.toggleChecked()
				}
			}

			model: DigitalClock.TimeZoneFilterProxy {
				sourceModel: timeZoneModel
				filterString: filter.text
			}

			delegate: RowLayout {
				id: delegateRoot
				width: timeZoneView.width
				spacing: Kirigami.Units.smallSpacing

				function setValue(newChecked) {
					if (!newChecked && region == "Local") {
						messageWidget.warn(i18n("Cannot deselect Local time from the tooltip"))
					} else {
						model.checked = newChecked
					}
				}

				function toggleChecked() {
					setValue(!checkedBox.checked)
				}

				MouseArea {
					anchors.fill: parent
					propagateComposedEvents: true
					onClicked: {
						timeZoneView.currentIndex = index
						mouse.accepted = false
					}
				}

				Label {
					text: city
					Layout.preferredWidth: page.cityColumnWidth
					elide: Text.ElideRight
				}
				Label {
					text: region
					Layout.preferredWidth: page.regionColumnWidth
					elide: Text.ElideRight
				}
				Label {
					text: comment
					Layout.fillWidth: true
					elide: Text.ElideRight
				}
				CheckBox {
					id: checkedBox
					Layout.preferredWidth: page.tooltipColumnWidth
					checked: model.checked
					onClicked: delegateRoot.setValue(checked)
				}
			}
		}

		ButtonGroup { id: timezoneDisplayType }
		RowLayout {
			Label {
				text: digitalclock_i18n("Display time zone as:")
			}

			RadioButton {
				id: timezoneCityRadio
				text: digitalclock_i18n("Time zone city")
				ButtonGroup.group: timezoneDisplayType
				checked: !plasmoid.configuration.displayTimezoneAsCode
				onClicked: plasmoid.configuration.displayTimezoneAsCode = false
			}

			RadioButton {
				id: timezoneCodeRadio
				text: digitalclock_i18n("Time zone code")
				ButtonGroup.group: timezoneDisplayType
				checked: plasmoid.configuration.displayTimezoneAsCode
				onClicked: plasmoid.configuration.displayTimezoneAsCode = true
			}
		}
	}
}
