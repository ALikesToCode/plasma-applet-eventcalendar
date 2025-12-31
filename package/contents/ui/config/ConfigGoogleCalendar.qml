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

	function markDirty() {
		if (typeof kcm !== "undefined") {
			kcm.needsSave = true
		}
	}

	function save() {
		if (typeof kcm !== "undefined") {
			kcm.needsSave = false
		}
	}

	function alphaColor(c, a) {
		return Qt.rgba(c.r, c.g, c.b, a)
	}
	readonly property color readablePositiveTextColor: Qt.tint(Kirigami.Theme.textColor, alphaColor(Kirigami.Theme.positiveTextColor, 0.5))
	readonly property color readableNegativeTextColor: Qt.tint(Kirigami.Theme.textColor, alphaColor(Kirigami.Theme.negativeTextColor, 0.5))

	function localFilePath(url) {
		var path = String(url)
		return path.indexOf("file://") === 0 ? path.slice(7) : path
	}

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
	function stringListEquals(listA, listB) {
		if (!Array.isArray(listA) || !Array.isArray(listB)) {
			return false
		}
		if (listA.length !== listB.length) {
			return false
		}
		for (var i = 0; i < listA.length; i++) {
			if (listA[i] !== listB[i]) {
				return false
			}
		}
		return true
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
	ExecUtil { id: callbackListener }

	property bool autoLoginInProgress: false
	readonly property bool localRedirect: googleLoginManager.redirectMode === "local"

	function extractJson(text) {
		var start = text.indexOf('{')
		var end = text.lastIndexOf('}')
		if (start >= 0 && end > start) {
			return text.slice(start, end + 1)
		}
		return ""
	}

	function startAutoLogin(accountId) {
		if (autoLoginInProgress) {
			return
		}
		googleLoginManager.resetPkce()
		autoLoginInProgress = true
		googleLoginManager.refreshClientCredentials()
		messageWidget.info(localRedirect
			? i18n("Waiting for browser callback...")
			: i18n("Waiting for the helper page to send the code..."))
		var cmd = [
			'python3',
			localFilePath(Qt.resolvedUrl("../../scripts/google_redirect.py")),
			'--client_id',
			googleLoginManager.effectiveClientId,
			'--listen_port',
			'53682',
			'--redirect_uri',
			googleLoginManager.redirectUri,
		]
		if (googleLoginManager.effectiveClientSecret) {
			cmd.push('--client_secret')
			cmd.push(googleLoginManager.effectiveClientSecret)
		}
		if (googleLoginManager.pkceVerifier) {
			cmd.push('--code_verifier')
			cmd.push(googleLoginManager.pkceVerifier)
		}
		Qt.openUrlExternally(googleLoginManager.authorizationCodeUrl)
		callbackListener.exec(cmd, function(cmd, exitCode, exitStatus, stdout, stderr) {
			autoLoginInProgress = false
			if (exitCode !== 0) {
				messageWidget.err(i18n("Auto login failed. See logs for details."))
				return
			}
			var payload = extractJson(stdout || "")
			if (!payload) {
				messageWidget.err(i18n("Auto login failed: no token data received."))
				return
			}
			var data = null
			try {
				data = JSON.parse(payload)
			} catch (e) {
				messageWidget.err(i18n("Auto login failed: invalid token data."))
				return
			}
			if (data.error) {
				messageWidget.err(i18n("Auto login failed: %1", data.error))
				return
			}
			authorizationCodeInput.text = ""
			googleLoginManager.updateAccessToken(data, accountId)
		})
	}

	GoogleLoginManager {
		id: googleLoginManager
		configBridge: page.configBridge
		redirectMode: page.cfg_googleRedirectMode || "local"
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
					description: item.description || "",
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

		onError: function(err) {
			messageWidget.err(err)
		}
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

	HeaderText {
		text: i18n("Client Credentials")
	}
	ColumnLayout {
		Layout.fillWidth: true

		MessageWidget {
			messageType: MessageWidget.MessageType.Warning
			closeButtonVisible: false
			text: googleLoginManager.normalizedClientValue(page.configBridge.read("customClientId", ""))
				? ""
				: i18n("The built-in Google OAuth client is often blocked. Provide your own client ID (and secret if required) to enable Google sync.")
		}
		Label {
			Layout.fillWidth: true
			text: i18n("Leave these empty to use the default credentials. Custom credentials require a Google Cloud OAuth client with the redirect URI set to %1.", googleLoginManager.redirectUri)
			color: readableNegativeTextColor
			wrapMode: Text.Wrap
		}
		RowLayout {
			Layout.fillWidth: true
			Label {
				text: i18n("Client ID")
			}
			ConfigString {
				configKey: "customClientId"
				Layout.fillWidth: true
				placeholderText: i18n("Optional")
				defaultValue: ""
				onTextChanged: {
					markDirty()
					googleLoginManager.refreshClientCredentials()
				}
			}
		}
		RowLayout {
			Layout.fillWidth: true
			Label {
				text: i18n("Client Secret")
			}
			ConfigString {
				configKey: "customClientSecret"
				Layout.fillWidth: true
				placeholderText: i18n("Optional")
				defaultValue: ""
				echoMode: TextInput.Password
				onTextChanged: {
					markDirty()
					googleLoginManager.refreshClientCredentials()
				}
			}
		}
	}

	HeaderText {
		text: i18n("Redirect Mode")
	}
	ColumnLayout {
		Layout.fillWidth: true

		ConfigRadioButtonGroup {
			label: i18n("Callback:")
			configKey: "googleRedirectMode"
			model: [
				{ value: "local", text: i18n("Localhost (auto capture)") },
				{ value: "hosted", text: i18n("Helper page (GitHub Pages)") },
			]
		}
		Label {
			Layout.fillWidth: true
			color: readableNegativeTextColor
			wrapMode: Text.Wrap
			text: localRedirect
				? i18n("Localhost keeps everything on your machine and supports auto capture.")
				: i18n("Helper page works without a localhost redirect. It will try to send the code back to the widget; if that fails, copy the code manually.")
		}
		Label {
			Layout.fillWidth: true
			color: readableNegativeTextColor
			wrapMode: Text.Wrap
			visible: !localRedirect
			text: i18n("Hosted mode requires your OAuth client to allow %1 as a redirect URI.", googleLoginManager.redirectUri)
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
			text: localRedirect
				? i18n("Visit <a href=\"%1\">%2</a> (opens in your web browser). After you login and grant access, your browser will redirect to a localhost URL. Copy the full URL (or just the code) and paste it below.", googleLoginManager.authorizationCodeUrl, 'https://accounts.google.com/...')
				: i18n("Visit <a href=\"%1\">%2</a> (opens in your web browser). After you login and grant access, your browser will redirect to the helper page, which will try to send the code back automatically.", googleLoginManager.authorizationCodeUrl, 'https://accounts.google.com/...')
			color: readableNegativeTextColor
			wrapMode: Text.Wrap
			onLinkActivated: function(link) {
				Qt.openUrlExternally(googleLoginManager.authorizationCodeUrl)
			}

			// Tooltip
			// QQC2.ToolTip.visible: !!hoveredLink
			// QQC2.ToolTip.text: googleLoginManager.authorizationCodeUrl

			// ContextMenu
			MouseArea {
				anchors.fill: parent
				acceptedButtons: Qt.RightButton
				onClicked: function(mouse) {
					if (mouse.button === Qt.RightButton) {
						contextMenu.popup()
					}
				}
				onPressAndHold: function(mouse) {
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
		LinkText {
			Layout.fillWidth: true
			text: localRedirect
				? i18n("Helper page (optional): <a href=\"%1\">%1</a>", googleLoginManager.hostedRedirectUri)
				: i18n("Helper page: <a href=\"%1\">%1</a>", googleLoginManager.redirectUri)
			color: readableNegativeTextColor
			wrapMode: Text.Wrap
		}
		Label {
			Layout.fillWidth: true
			color: readableNegativeTextColor
			wrapMode: Text.Wrap
			text: i18n("If your browser shows a connection error, that's expected. Copy the URL from the address bar anyway and paste it below.")
			visible: localRedirect
		}
		Label {
			Layout.fillWidth: true
			color: readableNegativeTextColor
			wrapMode: Text.Wrap
			text: localRedirect
				? i18n("Tip: Leave the field empty and click Add Account or Update Selected to auto-capture the callback.")
				: i18n("Tip: Click Add Account with an empty field to start the listener. If the helper page cannot reach the widget, copy the code manually and paste it below.")
			visible: true
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
				enabled: !autoLoginInProgress || !localRedirect
				onClicked: {
					if (authorizationCodeInput.text) {
						googleLoginManager.refreshClientCredentials()
						googleLoginManager.fetchAccessToken({
							authorizationCode: authorizationCodeInput.text,
						})
					} else {
						startAutoLogin("")
					}
				}
			}
			Button {
				visible: googleLoginManager.isLoggedIn
				text: i18n("Update Selected")
				enabled: !autoLoginInProgress || !localRedirect
				onClicked: {
					if (authorizationCodeInput.text) {
						googleLoginManager.refreshClientCredentials()
						googleLoginManager.fetchAccessToken({
							authorizationCode: authorizationCodeInput.text,
							accountId: googleLoginManager.activeAccountId,
						})
					} else {
						startAutoLogin(googleLoginManager.activeAccountId)
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
				if (!stringListEquals(calendarIdList, googleLoginManager.calendarIdList)) {
					googleLoginManager.setCalendarIdList(calendarIdList)
					markDirty()
				}
			}
		}

		ColumnLayout {
			Layout.fillWidth: true

			Repeater {
				model: calendarsModel
				delegate: CheckDelegate {
					id: calendarRow
					width: parent.width
					implicitHeight: Kirigami.Units.gridUnit * 2.5
					checkable: true
					hoverEnabled: true
					highlighted: hovered
					padding: Kirigami.Units.smallSpacing
					checked: model.show
					onToggled: {
						calendarsModel.setProperty(index, 'show', checked)
						calendarsModel.calendarsShownChanged()
					}

					contentItem: RowLayout {
						width: calendarRow.availableWidth - calendarRow.indicator.width - calendarRow.spacing
						height: calendarRow.availableHeight
						spacing: Kirigami.Units.smallSpacing

						Rectangle {
							Layout.alignment: Qt.AlignVCenter
							implicitWidth: Kirigami.Units.iconSizes.smallMedium
							implicitHeight: Kirigami.Units.iconSizes.smallMedium
							radius: 4
							color: model.backgroundColor
							border.width: 1
							border.color: Qt.rgba(syspal.text.r, syspal.text.g, syspal.text.b, 0.4)
						}

						Label {
							text: model.name
							Layout.fillWidth: true
							elide: Text.ElideRight
						}

						LockIcon {
							Layout.alignment: Qt.AlignVCenter
							implicitWidth: Kirigami.Units.iconSizes.smallMedium
							implicitHeight: Kirigami.Units.iconSizes.smallMedium
							visible: model.isReadOnly
						}
					}

					Accessible.name: model.name
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
				source: Qt.resolvedUrl("../../icons/google_tasks_96px.png")
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
				if (!stringListEquals(tasklistIdList, googleLoginManager.tasklistIdList)) {
					googleLoginManager.setTasklistIdList(tasklistIdList)
					markDirty()
				}
			}
		}

		ColumnLayout {
			Layout.fillWidth: true

			Repeater {
				model: tasklistsModel
				delegate: CheckDelegate {
					id: tasklistRow
					width: parent.width
					implicitHeight: Kirigami.Units.gridUnit * 2.5
					checkable: true
					hoverEnabled: true
					highlighted: hovered
					padding: Kirigami.Units.smallSpacing
					checked: model.show
					onToggled: {
						tasklistsModel.setProperty(index, 'show', checked)
						tasklistsModel.tasklistsShownChanged()
					}

					contentItem: RowLayout {
						width: tasklistRow.availableWidth - tasklistRow.indicator.width - tasklistRow.spacing
						height: tasklistRow.availableHeight
						spacing: Kirigami.Units.smallSpacing

						Rectangle {
							Layout.alignment: Qt.AlignVCenter
							implicitWidth: Kirigami.Units.iconSizes.smallMedium
							implicitHeight: Kirigami.Units.iconSizes.smallMedium
							radius: 4
							color: model.backgroundColor
							border.width: 1
							border.color: Qt.rgba(syspal.text.r, syspal.text.g, syspal.text.b, 0.4)
						}

						Label {
							text: model.name
							Layout.fillWidth: true
							elide: Text.ElideRight
						}

						LockIcon {
							Layout.alignment: Qt.AlignVCenter
							implicitWidth: Kirigami.Units.iconSizes.smallMedium
							implicitHeight: Kirigami.Units.iconSizes.smallMedium
							visible: model.isReadOnly
						}
					}

					Accessible.name: model.name
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
			onClicked: markDirty()
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
