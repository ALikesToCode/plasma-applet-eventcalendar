// Version 3 - Updated for Plasma 6

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.kirigami 2.20 as Kirigami

PlasmaComponents.CheckBox {
    id: configCheckBox

    property string configKey: ''
    property string toolTipText: ''

    checked: plasmoid.configuration[configKey]
    
    Kirigami.MnemonicData.enabled: true
    Kirigami.MnemonicData.controlType: Kirigami.MnemonicData.FormLabel
    
    // Use Plasma theme colors
    PlasmaComponents.ToolTip {
        text: configCheckBox.toolTipText
        visible: toolTipText !== '' && configCheckBox.hovered
    }

    onToggled: {
        plasmoid.configuration[configKey] = checked
    }

    // Ensure proper theme integration
    Kirigami.Theme.colorSet: Kirigami.Theme.View
    Kirigami.Theme.inherit: false
}
