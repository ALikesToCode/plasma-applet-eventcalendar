// Version 6

import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import QtQuick.Dialogs
import org.kde.kirigami 2.20 as Kirigami
import org.kde.plasma.components 3.0 as PlasmaComponents3

RowLayout {
    id: configSound
    property alias label: sfxEnabledCheckBox.text
    property alias sfxEnabledKey: sfxEnabledCheckBox.configKey
    property alias sfxPathKey: sfxPath.configKey

    property alias sfxEnabled: sfxEnabledCheckBox.checked
    property alias sfxPathValue: sfxPath.value
    property alias sfxPathDefaultValue: sfxPath.defaultValue

    // Using QtMultimedia is now more stable in Qt6/Plasma6
    property var sfxTest: null
    Component.onCompleted: {
        try {
            sfxTest = Qt.createQmlObject('import QtMultimedia; MediaPlayer {}', configSound)
        } catch (e) {
            console.warn("Could not create audio player:", e)
        }
    }

    spacing: Kirigami.Units.smallSpacing

    PlasmaComponents3.CheckBox {
        id: sfxEnabledCheckBox
        Kirigami.FormData.label: label
    }

    PlasmaComponents3.Button {
        icon.name: "media-playback-start"
        enabled: sfxEnabled && !!sfxTest
        onClicked: {
            if (sfxTest) {
                sfxTest.source = sfxPath.value
                sfxTest.play()
            }
        }
        PlasmaComponents3.ToolTip {
            text: i18n("Test Sound")
        }
    }

    ConfigString {
        id: sfxPath
        enabled: sfxEnabled
        Layout.fillWidth: true
    }

    PlasmaComponents3.Button {
        icon.name: "folder"
        enabled: sfxEnabled
        onClicked: sfxPathDialog.open()
        PlasmaComponents3.ToolTip {
            text: i18n("Choose Sound File")
        }

        FileDialog {
            id: sfxPathDialog
            title: i18n("Choose a sound effect")
            currentFolder: StandardPaths.standardLocations(StandardPaths.GenericDataLocation)[0] + "/sounds"
            nameFilters: [
                i18n("Sound files") + " (*.wav *.mp3 *.oga *.ogg)",
                i18n("All files") + " (*)"
            ]
            onAccepted: {
                sfxPathValue = selectedFile
            }
        }
    }
}
