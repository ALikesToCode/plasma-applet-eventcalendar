// Version 3 - Updated for Plasma 6

import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.20 as Kirigami
import org.kde.plasma.components 3.0 as PlasmaComponents3

RowLayout {
    id: configSlider

    property string configKey: ''
    property alias maximumValue: slider.to
    property alias minimumValue: slider.from 
    property alias stepSize: slider.stepSize
    property alias value: slider.value
    property alias live: slider.live

    property alias before: labelBefore.text
    property alias after: labelAfter.text

    Layout.fillWidth: true
    spacing: Kirigami.Units.smallSpacing

    PlasmaComponents3.Label {
        id: labelBefore
        text: ""
        visible: text
        color: Kirigami.Theme.textColor
    }
    
    PlasmaComponents3.Slider {
        id: slider
        Layout.fillWidth: configSlider.Layout.fillWidth
        
        from: 0
        to: 2147483647
        live: true
        
        value: plasmoid.configuration[configKey]
        onMoved: serializeTimer.restart()

        // Themed handle and groove
        handle: Rectangle {
            x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
            y: slider.topPadding + slider.availableHeight / 2 - height / 2
            width: Kirigami.Units.gridUnit
            height: width
            radius: width / 2
            color: slider.pressed ? Kirigami.Theme.highlightColor : Kirigami.Theme.backgroundColor
            border.color: Kirigami.Theme.highlightColor
        }
    }

    PlasmaComponents3.Label {
        id: labelAfter
        text: ""
        visible: text
        color: Kirigami.Theme.textColor
    }

    Timer {
        id: serializeTimer
        interval: 300
        onTriggered: {
            if (slider.value !== plasmoid.configuration[configKey]) {
                plasmoid.configuration[configKey] = slider.value
            }
        }
    }
}
