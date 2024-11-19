// Version 3 - Updated for Plasma 6

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.kirigami 2.20 as Kirigami

PlasmaComponents.TextField {
    id: configString
    Layout.fillWidth: true
    
    property string configKey: ''
    property alias value: configString.text
    readonly property string configValue: configKey ? plasmoid.configuration[configKey] : ""
    
    // Use Kirigami theme colors
    color: Kirigami.Theme.textColor
    
    // Improved focus handling
    onConfigValueChanged: {
        if (!configString.focus && value != configValue) {
            value = configValue
        }
    }
    
    property string defaultValue: ""
    
    text: configString.configValue
    onTextChanged: serializeTimer.restart()
    
    PlasmaComponents.ToolButton {
        id: clearButton
        icon.name: "edit-clear"
        onClicked: configString.value = defaultValue
        
        anchors {
            top: parent.top
            right: parent.right
            bottom: parent.bottom
        }
        
        width: height
        
        // Add tooltip
        Kirigami.MnemonicData.enabled: true
        Kirigami.MnemonicData.controlType: Kirigami.MnemonicData.SecondaryControl
        PlasmaComponents.ToolTip {
            text: i18n("Reset to default value")
        }
    }
    
    Timer {
        id: serializeTimer
        interval: 300
        onTriggered: {
            if (configKey) {
                plasmoid.configuration[configKey] = value
            }
        }
    }
    
    // Add visual feedback when value differs from default
    Rectangle {
        visible: configString.text !== defaultValue
        anchors.right: clearButton.left
        anchors.verticalCenter: parent.verticalCenter
        width: Kirigami.Units.smallSpacing
        height: Kirigami.Units.gridUnit
        color: Kirigami.Theme.neutralTextColor
        opacity: 0.5
        radius: width / 2
    }
}
