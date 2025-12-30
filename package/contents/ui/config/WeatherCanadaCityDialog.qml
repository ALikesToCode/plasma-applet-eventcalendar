import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kitemmodels as KItemModels

import "../lib/Requests.js" as Requests
import ".."
import "../weather/WeatherCanada.js" as WeatherCanada

Dialog {
	id: chooseCityDialog
	title: i18n("Select city")
	standardButtons: Dialog.Ok | Dialog.Cancel
	modal: true

	width: 500
	height: 600
	property bool loadingCityList: false
	property bool cityListLoaded: false

	property string selectedCityId: ""
	property alias provinceIdList: provinceRepeater.model

	ListModel { id: emptyListModel }
	ListModel { id: cityListModel }
	KItemModels.KSortFilterProxyModel {
		id: filteredCityListModel
		// sourceModel: cityListModel // Link after populating cityListModel so the UI doesn't freeze.
		sourceModel: emptyListModel
		filterRoleName: "name"
		sortRoleName: "name"
		filterCaseSensitivity: Qt.CaseInsensitive
		sortCaseSensitivity: Qt.CaseInsensitive
		filterRegularExpression: RegExp("")
	}

	Timer {
		id: debouceApplyFilter
		interval: 1000
		onTriggered: chooseCityDialog.applyFilter()
	}

	onVisibleChanged: {
		if (visible && !cityListLoaded && !loadingCityList) {
			loadProvinceCityList()
		}
	}

	ColumnLayout {
		anchors.fill: parent
		spacing: Kirigami.Units.smallSpacing

		LinkText {
			text: i18n("Fetched from <a href=\"%1\">%1</a>", "https://weather.gc.ca/canada_e.html")
		}

		TabBar {
			id: provinceTabBar
			Layout.fillWidth: true
			Repeater {
				id: provinceRepeater
				model: ["AB", "BC", "MB", "NB", "NL", "NS", "NT", "NU", "ON", "PE", "QC", "SK", "YT"]
				TabButton { text: modelData }
			}
			onCurrentIndexChanged: loadProvinceCityList()
		}

		TextField {
			id: cityNameInput
			Layout.fillWidth: true
			text: ""
			placeholderText: i18n("Search")
			onTextChanged: debouceApplyFilter.restart()
		}

		RowLayout {
			Layout.fillWidth: true
			spacing: Kirigami.Units.smallSpacing

			Label {
				text: i18n("Name")
				font.bold: true
				Layout.preferredWidth: Kirigami.Units.gridUnit * 10
			}
			Label {
				text: i18n("Id")
				font.bold: true
				Layout.preferredWidth: Kirigami.Units.gridUnit * 6
			}
			Label {
				text: i18n("City Webpage")
				font.bold: true
				Layout.fillWidth: true
			}
		}

		ListView {
			id: cityListView
			Layout.fillWidth: true
			Layout.fillHeight: true
			Layout.minimumHeight: 200
			clip: true
			focus: true
			highlightFollowsCurrentItem: true
			highlight: Rectangle {
				color: Kirigami.Theme.highlightColor
				opacity: 0.15
			}
			model: filteredCityListModel

			delegate: RowLayout {
				width: cityListView.width
				spacing: Kirigami.Units.smallSpacing

				MouseArea {
					anchors.fill: parent
					propagateComposedEvents: true
					onClicked: {
						cityListView.currentIndex = index
						chooseCityDialog.selectedCityId = cityId
						mouse.accepted = false
					}
					onDoubleClicked: chooseCityDialog.accept()
				}

				Label {
					text: name
					elide: Text.ElideRight
					Layout.preferredWidth: Kirigami.Units.gridUnit * 10
				}
				Label {
					text: cityId
					elide: Text.ElideRight
					Layout.preferredWidth: Kirigami.Units.gridUnit * 6
				}
				LinkText {
					Layout.fillWidth: true
					text: "<a href=\"https://weather.gc.ca/city/pages/" + cityId + "_metric_e.html\">" + i18n("Open Link") + "</a>"
					linkColor: cityListView.currentIndex === index ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.linkColor
				}
			}

			BusyIndicator {
				anchors.centerIn: parent
				running: visible
				visible: chooseCityDialog.loadingCityList
			}
		}
	}

	function applyFilter() {
		if (cityNameInput.text) {
			filteredCityListModel.filterRegularExpression = RegExp(cityNameInput.text, "i")
		} else {
			filteredCityListModel.filterRegularExpression = RegExp("")
		}
		chooseCityDialog.selectedCityId = ""
	}

	function loadCityList(provinceUrl) {
		chooseCityDialog.loadingCityList = true
		filteredCityListModel.sourceModel = emptyListModel
		cityListModel.clear()

		Requests.request(provinceUrl, function(err, data) {
			if (err) {
				console.log("[eventcalendar]", "loadCityList.err", err, data)
				chooseCityDialog.loadingCityList = false
				return
			}
			var cityList = WeatherCanada.parseProvincePage(data)
			for (var i = 0; i < cityList.length; i++) {
				cityListModel.append({
					cityId: cityList[i].id,
					name: cityList[i].name,
				})
			}

			// Link after populating so each append() doesn't attempt to rebuild the UI.
			if (filteredCityListModel) {
				filteredCityListModel.sourceModel = cityListModel
			}

			chooseCityDialog.cityListLoaded = true
			chooseCityDialog.loadingCityList = false
		})
	}

	function loadProvinceCityList() {
		var provinceId = provinceIdList[0]
		if (provinceTabBar.currentIndex >= 0) {
			provinceId = provinceIdList[provinceTabBar.currentIndex]
		}

		var provinceUrl = "https://weather.gc.ca/forecast/canada/index_e.html?id=" + provinceId
		loadCityList(provinceUrl)
	}
}
