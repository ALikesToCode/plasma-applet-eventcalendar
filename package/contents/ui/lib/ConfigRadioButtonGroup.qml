// Version 5

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.kirigami 2.20 as Kirigami

/*
** Example:
**
ConfigRadioButtonGroup {
    configKey: "appDescription"
    label: i18n("Select an option:")
    model: [
        { value: "a", text: i18n("Option A"), icon: "document-edit" },
        { value: "b", text: i18n("Option B"), icon: "document-save" },
        { value: "c", text: i18n("Option C"), icon: "document-share" },
    ]
}
*/

RowLayout {
    id: configRadioButtonGroup
    Layout.fillWidth: true
    default property alias _contentChildren: content.data
    property alias label: groupLabel.text
    
    property string configKey: ''
    readonly property var configValue: configKey ? plasmoid.configuration[configKey] : ""
    property alias model: buttonRepeater.model

    spacing: Kirigami.Units.smallSpacing

    PlasmaComponents.Label {
        id: groupLabel
        visible: text.length > 0
        Layout.alignment: Qt.AlignTop | Qt.AlignLeft
        color: Kirigami.Theme.textColor
    }

    ColumnLayout {
        id: content
        spacing: Kirigami.Units.smallSpacing

        ButtonGroup {
            id: radioButtonGroup
            exclusive: true
        }

        Repeater {
            id: buttonRepeater
            
            PlasmaComponents.RadioButton {
                id: radioButton
                visible: typeof modelData.visible !== "undefined" ? modelData.visible : true
                enabled: typeof modelData.enabled !== "undefined" ? modelData.enabled : true
                text: modelData.text
                checked: modelData.value === configValue
                ButtonGroup.group: radioButtonGroup
                
                icon.name: modelData.icon || ""
                display: modelData.icon ? PlasmaComponents.RadioButton.TextBesideIcon : PlasmaComponents.RadioButton.TextOnly
                
                Kirigami.MnemonicData.enabled: true
                Kirigami.MnemonicData.controlType: Kirigami.MnemonicData.SecondaryControl
                
                Layout.fillWidth: true
                
                onClicked: {
                    focus = true
                    if (configKey) {
                        plasmoid.configuration[configKey] = modelData.value
                    }
                }

                ToolTip.visible: hovered && modelData.tooltip
                ToolTip.text: modelData.tooltip || ""
                ToolTip.delay: Kirigami.Units.toolTipDelay
            }
        }
    }
}
