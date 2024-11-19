// Version 3

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.20 as Kirigami
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.plasma.core 2.0 as PlasmaCore

GridLayout {
    id: configDimension
    columnSpacing: Kirigami.Units.smallSpacing
    rowSpacing: Kirigami.Units.smallSpacing

    property int orientation: Qt.Horizontal
    property color lineColor: Kirigami.Theme.textColor
    property int lineThickness: Math.max(1, Math.floor(2 * Kirigami.Units.devicePixelRatio))

    property alias configKey: configSpinBox.configKey
    property alias configValue: configSpinBox.configValue
    property alias horizontalAlignment: configSpinBox.horizontalAlignment
    property alias maximumValue: configSpinBox.maximumValue
    property alias minimumValue: configSpinBox.minimumValue
    property alias prefix: configSpinBox.prefix
    property alias stepSize: configSpinBox.stepSize
    property alias suffix: configSpinBox.suffix
    property alias value: configSpinBox.value

    property alias before: configSpinBox.before
    property alias after: configSpinBox.after

    states: [
        State {
            name: "horizontal"
            when: orientation == Qt.Horizontal

            PropertyChanges { 
                target: configDimension
                rows: 1
            }
            PropertyChanges { 
                target: lineA
                implicitWidth: configDimension.lineThickness
                Layout.fillHeight: true
            }
            PropertyChanges { 
                target: lineSpanA
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                implicitHeight: configDimension.lineThickness
            }
            PropertyChanges { 
                target: configSpinBox
                Layout.alignment: Qt.AlignVCenter
            }
            PropertyChanges { 
                target: lineSpanB
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                implicitHeight: configDimension.lineThickness
            }
            PropertyChanges { 
                target: lineB
                implicitWidth: configDimension.lineThickness
                Layout.fillHeight: true
            }
        },
        State {
            name: "vertical"
            when: orientation == Qt.Vertical

            PropertyChanges { 
                target: configDimension
                columns: 1
            }
            PropertyChanges { 
                target: lineA
                Layout.alignment: Qt.AlignHCenter
                implicitHeight: configDimension.lineThickness
                implicitWidth: configSpinBox.implicitHeight
            }
            PropertyChanges { 
                target: lineSpanA
                Layout.fillHeight: true
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: configDimension.lineThickness
            }
            PropertyChanges { 
                target: configSpinBox
                Layout.alignment: Qt.AlignHCenter
            }
            PropertyChanges { 
                target: lineSpanB
                Layout.fillHeight: true
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: configDimension.lineThickness
            }
            PropertyChanges { 
                target: lineB
                Layout.alignment: Qt.AlignHCenter
                implicitHeight: configDimension.lineThickness
                implicitWidth: configSpinBox.implicitHeight
            }
        }
    ]

    Rectangle {
        id: lineA
        color: configDimension.lineColor
        opacity: Kirigami.Theme.invertedColorScheme ? 0.7 : 0.4
        Behavior on color { ColorAnimation { duration: Kirigami.Units.shortDuration } }
    }
    Rectangle {
        id: lineSpanA
        color: configDimension.lineColor
        opacity: Kirigami.Theme.invertedColorScheme ? 0.7 : 0.4
        Behavior on color { ColorAnimation { duration: Kirigami.Units.shortDuration } }
    }
    PlasmaComponents3.SpinBox {
        id: configSpinBox
        Layout.minimumWidth: Kirigami.Units.gridUnit * 8
    }
    Rectangle {
        id: lineSpanB
        color: configDimension.lineColor
        opacity: Kirigami.Theme.invertedColorScheme ? 0.7 : 0.4
        Behavior on color { ColorAnimation { duration: Kirigami.Units.shortDuration } }
    }
    Rectangle {
        id: lineB
        color: configDimension.lineColor
        opacity: Kirigami.Theme.invertedColorScheme ? 0.7 : 0.4
        Behavior on color { ColorAnimation { duration: Kirigami.Units.shortDuration } }
    }
}
