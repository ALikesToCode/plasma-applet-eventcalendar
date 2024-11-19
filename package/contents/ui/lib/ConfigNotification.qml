// Version 6

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.kirigami 2.20 as Kirigami
import org.kde.plasma.plasmoid 2.0

ColumnLayout {
    id: configNotification
    spacing: Kirigami.Units.smallSpacing

    property alias label: notificationEnabledSwitch.text
    property alias notificationEnabledKey: notificationEnabledSwitch.configKey
    property alias notificationEnabled: notificationEnabledSwitch.checked

    property alias sfxLabel: configSound.label
    property alias sfxEnabledKey: configSound.sfxEnabledKey
    property alias sfxPathKey: configSound.sfxPathKey

    property alias sfxEnabled: configSound.sfxEnabled
    property alias sfxPathValue: configSound.sfxPathValue
    property alias sfxPathDefaultValue: configSound.sfxPathDefaultValue

    property int indentWidth: Kirigami.Units.largeSpacing * 2

    PlasmaComponents.Switch {
        id: notificationEnabledSwitch
        Kirigami.FormData.label: i18nc("@label:checkbox", "Enable Notifications")
        checked: Plasmoid.configuration[configKey] ?? false
        onCheckedChanged: {
            if (configKey) {
                Plasmoid.configuration[configKey] = checked
            }
        }
    }

    RowLayout {
        spacing: Kirigami.Units.smallSpacing
        Item { 
            implicitWidth: indentWidth
            implicitHeight: Kirigami.Units.gridUnit 
        }
        ConfigSound {
            id: configSound
            label: i18nc("@label:textbox", "Sound Effect:")
            enabled: notificationEnabled
            Layout.fillWidth: true
            Kirigami.FormData.buddyFor: soundFileField
        }
    }

    Kirigami.Separator {
        Layout.fillWidth: true
        visible: notificationEnabled
    }
}
