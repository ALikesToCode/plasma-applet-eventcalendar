import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kitemmodels as KItemModels

import ".."
import "../lib"
import "../lib/Requests.js" as Requests

Dialog {
	id: chooseCityDialog
	title: i18n("Select city")
	standardButtons: Dialog.Ok | Dialog.Cancel
	modal: true

	width: 500
	height: 600
	property bool loadingCityList: false

	Logger {
		id: logger
		showDebug: plasmoid.configuration.debugging
	}

	ListModel { id: cityListModel }
	KItemModels.KSortFilterProxyModel {
		id: filteredCityListModel
		// sourceModel: cityListModel // Link after populating cityListModel so the UI doesn't freeze.
		filterRoleName: "name"
		sortRoleName: "name"
		filterCaseSensitivity: Qt.CaseInsensitive
		sortCaseSensitivity: Qt.CaseInsensitive
		filterRegularExpression: RegExp("")
	}

	property string selectedCityId: ""

	Timer {
		id: debouceApplyFilter
		interval: 1000
		onTriggered: chooseCityDialog.applyCityListSearch()
	}

	ColumnLayout {
		anchors.fill: parent
		spacing: Kirigami.Units.smallSpacing

		LinkText {
			text: i18n("Fetched from <a href=\"%1\">%1</a>", "https://openweathermap.org/find")
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
					text: "<a href=\"https://openweathermap.org/city/" + cityId + "\">" + i18n("Open Link") + "</a>"
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

	function clearCityList() {
		// clear list so that each append() doesn't rebuild the UI
		filteredCityListModel.sourceModel = null
		cityListModel.clear()
	}

	function parseCityList(data) {
		for (var i = 0; i < data.list.length; i++) {
			var item = data.list[i]
			cityListModel.append({
				cityId: item.id,
				name: item.name + ", " + item.sys.country,
			})
		}
	}

	function applyCityListSearch() {
		searchCityList(cityNameInput.text)
	}

	function searchCityList(q) {
		logger.debug("searchCityList", q)
		clearCityList()
		if (q) {
			chooseCityDialog.loadingCityList = true
			fetchCityList({
				appId: plasmoid.configuration.openWeatherMapAppId,
				q: q,
			}, function(err, data, xhr) {
				if (err) return console.log("searchCityList.err", err, xhr && xhr.status, data)
				logger.debug("searchCityList.response")
				logger.debugJSON("searchCityList.response", data)

				parseCityList(data)

				// link after populating so that each append() doesn't attempt to rebuild the UI.
				filteredCityListModel.sourceModel = cityListModel

				chooseCityDialog.loadingCityList = false
			})
		}
	}

	function fetchCityList(args, callback) {
		if (!args.appId) return callback("OpenWeatherMap AppId not set")

		var url = "https://api.openweathermap.org/data/2.5/"
		url += "find?q=" + encodeURIComponent(args.q)
		url += "&type=like"
		url += "&sort=population"
		url += "&cnt=30"
		url += "&appid=" + args.appId
		Requests.getJSON(url, callback)
	}
}
