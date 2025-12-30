import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

import ".."
import "../lib"
import "../lib/Requests.js" as Requests

ConfigPage {
	id: page

	SystemPalette { id: syspal }

	function alphaColor(c, a) {
		return Qt.rgba(c.r, c.g, c.b, a)
	}
	readonly property color readablePositiveTextColor: Qt.tint(Kirigami.Theme.textColor, alphaColor(Kirigami.Theme.positiveTextColor, 0.5))
	readonly property color readableNegativeTextColor: Qt.tint(Kirigami.Theme.textColor, alphaColor(Kirigami.Theme.negativeTextColor, 0.5))

	function sortByKey(key, a, b){
		if (typeof a[key] === "string") {
			return a[key].toLowerCase().localeCompare(b[key].toLowerCase())
		} else if (typeof a[key] === "number") {
			return a[key] - b[key]
		} else {
			return 0
		}
	}
	function sortArr(arr, predicate) {
		if (typeof predicate === "string") { // predicate is a key
			predicate = sortByKey.bind(null, predicate)
		}
		return arr.concat().sort(predicate)
	}

	property int selectedAccountIndex: 0
	function accountLabel(account, index) {
		if (!account) {
			return i18n("Google Account")
		}
		return account.label || i18n("Google Account %1", index + 1)
	}
	function rebuildAccountsModel() {
		accountsModel.clear()
		var accounts = googleLoginManager.accounts || []
		var nextIndex = 0
		for (var i = 0; i < accounts.length; i++) {
			var account = accounts[i]
			if (account && account.id === googleLoginManager.activeAccountId) {
				nextIndex = i
			}
			accountsModel.append({
				accountId: account.id,
				label: accountLabel(account, i),
			})
		}
		selectedAccountIndex = nextIndex
		if (typeof accountSelector !== 'undefined') {
			accountSelector.currentIndex = nextIndex
		}
	}

	ListModel { id: accountsModel }

	GoogleLoginManager {
		id: googleLoginManager
		onAccountsChanged: rebuildAccountsModel()
		onActiveAccountIdChanged: rebuildAccountsModel()

		onCalendarListChanged: {
			calendarsModel.clear()
			var sortedList = sortArr(calendarList, "summary")
			for (var i = 0; i < sortedList.length; i++) {
				var item = sortedList[i]
				// console.log(JSON.stringify(item))
				var isPrimary = item.primary === true
				var isShown = calendarIdList.indexOf(item.id) >= 0 || (isPrimary && calendarIdList.indexOf('primary') >= 0)
				calendarsModel.append({
					calendarId: item.id, 
					name: item.summary,
					description: item.description,
					backgroundColor: item.backgroundColor,
					foregroundColor: item.foregroundColor,
					show: isShown,
					isReadOnly: item.accessRole == "reader",
				})
				// console.log(item.summary, isShown, item.id)
			}
			calendarsModel.calendarsShownChanged()
		}

		onTasklistListChanged: {
			tasklistsModel.clear()
			var sortedList = sortArr(tasklistList, "title")
			for (var i = 0; i < sortedList.length; i++) {
				var item = sortedList[i]
				// console.log(JSON.stringify(item))
				var isShown = tasklistIdList.indexOf(item.id) >= 0
				tasklistsModel.append({
					tasklistId: item.id, 
					name: item.title,
					description: '',
					backgroundColor: Kirigami.Theme.highlightColor.toString(),
					foregroundColor: Kirigami.Theme.highlightedTextColor.toString(),
					show: isShown,
					isReadOnly: false,
				})
				// console.log(item.summary, isShown, item.id)
			}
			tasklistsModel.tasklistsShownChanged()
		}

		onError: messageWidget.err(err)
	}


	HeaderText {
		text: i18n("Accounts")
	}
	MessageWidget {
		id: messageWidget
	}
	ColumnLayout {
		visible: googleLoginManager.isLoggedIn
		RowLayout {
			Layout.fillWidth: true
			Label {
				text: i18n("Account")
			}
			ComboBox {
				id: accountSelector
				Layout.fillWidth: true
				textRole: "label"
				model: accountsModel
				onActivated: {
					var item = accountsModel.get(currentIndex)
					if (item && item.accountId) {
						googleLoginManager.setActiveAccountId(item.accountId)
					}
				}
			}
			Button {
				text: i18n("Remove")
				enabled: accountsModel.count > 0
				onClicked: {
					googleLoginManager.removeAccount(googleLoginManager.activeAccountId)
					calendarsModel.clear()
					tasklistsModel.clear()
				}
			}
		}
		Label {
			Layout.fillWidth: true
			text: i18n("Currently Synced: %1", accountLabel(googleLoginManager.activeAccount, accountSelector.currentIndex))
			color: readablePositiveTextColor
			wrapMode: Text.Wrap
		}
		MessageWidget {
			visible: googleLoginManager.needsRelog
			text: i18n("Widget has been updated. Please logout and login to Google Calendar again.")
		}
	}
	ColumnLayout {
		Label {
			Layout.fillWidth: true
			text: googleLoginManager.isLoggedIn
				? i18n("Add another Google account")
				: i18n("To sync with Google Calendar")
			color: readableNegativeTextColor
			wrapMode: Text.Wrap
		}
		LinkText {
			Layout.fillWidth: true
			text: i18n("Visit <a href=\"%1\">%2</a> (opens in your web browser). After you login and grant access, your browser will redirect to a localhost URL. Copy the full URL (or just the code) and paste it below.", googleLoginManager.authorizationCodeUrl, 'https://accounts.google.com/...')
			color: readableNegativeTextColor
			wrapMode: Text.Wrap

			// Tooltip
			// QQC2.ToolTip.visible: !!hoveredLink
			// QQC2.ToolTip.text: googleLoginManager.authorizationCodeUrl

			// ContextMenu
			MouseArea {
				anchors.fill: parent
				acceptedButtons: Qt.RightButton
				onClicked: {
					if (mouse.button === Qt.RightButton) {
						contextMenu.popup()
					}
				}
				onPressAndHold: {
					if (mouse.source === Qt.MouseEventNotSynthesized) {
						contextMenu.popup()
					}
				}

				Menu {
					id: contextMenu
					MenuItem {
						text: i18n("Copy Link")
						onTriggered: clipboardHelper.copyText(googleLoginManager.authorizationCodeUrl)
					}
				}

				TextEdit {
					id: clipboardHelper
					visible: false
					function copyText(text) {
						clipboardHelper.text = text
						clipboardHelper.selectAll()
						clipboardHelper.copy()
					}
				}
			}
		}
		Label {
			Layout.fillWidth: true
			color: readableNegativeTextColor
			wrapMode: Text.Wrap
			text: i18n("If your browser shows a connection error, that's expected. Copy the URL from the address bar anyway and paste it below.")
		}
		RowLayout {
			TextField {
				id: authorizationCodeInput
				Layout.fillWidth: true

				placeholderText: i18n("Paste the authorization code or redirect URL here")
				text: ""
			}
			Button {
				text: googleLoginManager.isLoggedIn ? i18n("Add Account") : i18n("Submit")
				onClicked: {
					if (authorizationCodeInput.text) {
						googleLoginManager.fetchAccessToken({
							authorizationCode: authorizationCodeInput.text,
						})
					} else {
						messageWidget.err(i18n("Invalid Google Authorization Code"))
					}
				}
			}
			Button {
				visible: googleLoginManager.isLoggedIn
				text: i18n("Update Selected")
				onClicked: {
					if (authorizationCodeInput.text) {
						googleLoginManager.fetchAccessToken({
							authorizationCode: authorizationCodeInput.text,
							accountId: googleLoginManager.activeAccountId,
						})
					} else {
						messageWidget.err(i18n("Invalid Google Authorization Code"))
					}
				}
			}
		}
		
	}

	RowLayout {
		Layout.fillWidth: true
		visible: googleLoginManager.isLoggedIn

		HeaderText {
			text: i18n("Calendars")
		}

		Button {
			icon.name: "view-refresh"
			text: i18n("Refresh")
			onClicked: googleLoginManager.updateCalendarList()
		}
	}
	ColumnLayout {
		spacing: Kirigami.Units.smallSpacing * 2
		Layout.fillWidth: true
		visible: googleLoginManager.isLoggedIn

		ListModel {
			id: calendarsModel

			signal calendarsShownChanged()

			onCalendarsShownChanged: {
				var calendarIdList = []
				for (var i = 0; i < calendarsModel.count; i++) {
					var item = calendarsModel.get(i)
					if (item.show) {
						calendarIdList.push(item.calendarId)
					}
				}
				googleLoginManager.setCalendarIdList(calendarIdList)
			}
		}

		ColumnLayout {
			Layout.fillWidth: true

			Repeater {
				model: calendarsModel
				delegate: CheckBox {
					id: calendarCheckBox
					text: model.name
					checked: model.show
					indicator: Rectangle {
						implicitWidth: 12
						implicitHeight: 12
						radius: 3
						border.width: 1
						border.color: syspal.text
						color: calendarCheckBox.checked ? model.backgroundColor : syspal.base
						Label {
							visible: calendarCheckBox.checked
							text: "✓"
							color: model.foregroundColor
							font.pixelSize: 8
							anchors.centerIn: parent
						}
					}
					contentItem: RowLayout {
						Rectangle {
							Layout.fillHeight: true
							Layout.preferredWidth: height
							color: model.backgroundColor
						}
						Label {
							text: calendarCheckBox.text
						}
						LockIcon {
							Layout.fillHeight: true
							Layout.preferredWidth: height
							visible: model.isReadOnly
						}
					}

					onClicked: {
						calendarsModel.setProperty(index, 'show', checked)
						calendarsModel.calendarsShownChanged()
					}
				}
			}
		}
	}

	RowLayout {
		Layout.fillWidth: true
		visible: googleLoginManager.isLoggedIn

		HeaderText {
			text: i18n("Tasks")

			Image {
				source: plasmoid.file("", "icons/google_tasks_96px.png")
				smooth: true
				anchors.leftMargin: parent.contentWidth + Kirigami.Units.smallSpacing
				anchors.left: parent.left
				anchors.verticalCenter: parent.verticalCenter
				width: Kirigami.Units.iconSizes.smallMedium
				height: Kirigami.Units.iconSizes.smallMedium
			}
		}

		Button {
			icon.name: "view-refresh"
			text: i18n("Refresh")
			onClicked: googleLoginManager.updateTasklistList()
		}
	}
	ColumnLayout {
		spacing: Kirigami.Units.smallSpacing * 2
		Layout.fillWidth: true
		visible: googleLoginManager.isLoggedIn

		ListModel {
			id: tasklistsModel

			signal tasklistsShownChanged()

			onTasklistsShownChanged: {
				var tasklistIdList = []
				for (var i = 0; i < tasklistsModel.count; i++) {
					var item = tasklistsModel.get(i)
					if (item.show) {
						tasklistIdList.push(item.tasklistId)
					}
				}
				googleLoginManager.setTasklistIdList(tasklistIdList)
			}
		}

		ColumnLayout {
			Layout.fillWidth: true

			Repeater {
				model: tasklistsModel
				delegate: CheckBox {
					id: tasklistCheckBox
					text: model.name
					checked: model.show
					indicator: Rectangle {
						implicitWidth: 12
						implicitHeight: 12
						radius: 3
						border.width: 1
						border.color: syspal.text
						color: tasklistCheckBox.checked ? model.backgroundColor : syspal.base
						Label {
							visible: tasklistCheckBox.checked
							text: "✓"
							color: model.foregroundColor
							font.pixelSize: 8
							anchors.centerIn: parent
						}
					}
					contentItem: RowLayout {
						Rectangle {
							Layout.fillHeight: true
							Layout.preferredWidth: height
							color: model.backgroundColor
						}
						Label {
							text: tasklistCheckBox.text
						}
						LockIcon {
							Layout.fillHeight: true
							Layout.preferredWidth: height
							visible: model.isReadOnly
						}
					}

					onClicked: {
						tasklistsModel.setProperty(index, 'show', checked)
						tasklistsModel.tasklistsShownChanged()
					}
				}
			}
		}
	}

	HeaderText {
		text: i18n("Options")
		visible: googleLoginManager.isLoggedIn
	}

	ColumnLayout {
		Layout.fillWidth: true
		visible: googleLoginManager.isLoggedIn

		ConfigRadioButtonGroup {
			id: googleEventClickAction
			label: i18n("Event Click:")
			configKey: 'googleEventClickAction'
			model: [
				{ value: 'WebEventView', text: i18n("Open Web Event View") },
				{ value: 'WebMonthView', text: i18n("Open Web Month View") },
			]
		}

		ConfigCheckBox {
			configKey: 'googleHideGoalsDesc'
			text: i18n("Hide \"This event was added from Goals in Google Calendar\" description")
		}
	}

	Component.onCompleted: {
		rebuildAccountsModel()
		if (googleLoginManager.isLoggedIn) {
			googleLoginManager.calendarListChanged()
			googleLoginManager.tasklistListChanged()
		}
	}
}
