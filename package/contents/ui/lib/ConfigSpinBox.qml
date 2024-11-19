// Version 4

import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.kirigami 2.20 as Kirigami

RowLayout {
    id: configSpinBox

    property string configKey: ''
    readonly property var configValue: configKey ? plasmoid.configuration[configKey] : 0
    property alias decimals: spinBox.decimals 
    property alias horizontalAlignment: spinBox.horizontalAlignment
    property alias maximumValue: spinBox.maximumValue
    property alias minimumValue: spinBox.minimumValue
    property alias prefix: spinBox.prefix
    property alias stepSize: spinBox.stepSize
    property alias suffix: spinBox.suffix
    property alias value: spinBox.value

    property alias before: labelBefore.text
    property alias after: labelAfter.text

    PlasmaComponents.Label {
        id: labelBefore
        text: ""
        visible: text
        color: Kirigami.Theme.textColor
    }
    
    PlasmaComponents.SpinBox {
        id: spinBox
        
        value: configValue
        onValueChanged: serializeTimer.start()
        maximumValue: 2147483647
        
        // Modern styling
        editable: true
        from: minimumValue
        to: maximumValue
        
        background: Rectangle {
            color: Kirigami.Theme.backgroundColor
            border.color: spinBox.activeFocus ? Kirigami.Theme.highlightColor : Kirigami.Theme.disabledTextColor
            border.width: 1
            radius: 4
        }
    }

    PlasmaComponents.Label {
        id: labelAfter
        text: ""
        visible: text
        color: Kirigami.Theme.textColor
    }

    Timer { // throttle
        id: serializeTimer
        interval: 300
        onTriggered: {
            if (configKey) {
                plasmoid.configuration[configKey] = value
            }
        }
    }
}
