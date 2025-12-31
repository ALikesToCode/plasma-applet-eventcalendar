// Version 5

import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

RowLayout {
	id: configSound
	property alias label: sfxEnabledCheckBox.text
	property alias sfxEnabledKey: sfxEnabledCheckBox.configKey
	property alias sfxPathKey: sfxPath.configKey

	property alias sfxEnabled: sfxEnabledCheckBox.checked
	property alias sfxPathValue: sfxPath.value
	property alias sfxPathDefaultValue: sfxPath.defaultValue

	// Importing QtMultimedia apparently segfaults both OpenSUSE and Kubuntu.
	// https://github.com/Zren/plasma-applet-eventcalendar/issues/84
	// https://github.com/Zren/plasma-applet-eventcalendar/issues/167
	// property var sfxTest: Qt.createQmlObject("import QtMultimedia 5.4; Audio {}", configSound)
	property var sfxTest: null

	spacing: 0
	ConfigCheckBox {
		id: sfxEnabledCheckBox
	}
	Button {
		icon.name: "media-playback-start-symbolic"
		enabled: sfxEnabled && !!sfxTest
		onClicked: {
			sfxTest.source = sfxPath.value
			sfxTest.play()
		}
	}
	ConfigString {
		id: sfxPath
		enabled: sfxEnabled
		Layout.fillWidth: true
	}
	Button {
		icon.name: "folder-symbolic"
		enabled: sfxEnabled
		onClicked: sfxPathDialog.open()

		FileDialog {
			id: sfxPathDialog
			title: i18n("Choose a sound effect")
			currentFolder: "file:///usr/share/sounds"
			nameFilters: [
				i18n("Sound files (%1)", "*.wav *.mp3 *.oga *.ogg"),
				i18n("All files (%1)", "*"),
			]
			onAccepted: {
				sfxPathValue = selectedFile.toString()
			}
		}
	}
}
