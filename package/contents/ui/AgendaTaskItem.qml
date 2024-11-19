import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import org.kde.plasma.components 3.0 as PlasmaComponents3

Plasmoid.fullRepresentation: Item {
    id: root
    
    // Minimum size constraints
    Layout.minimumWidth: Kirigami.Units.gridUnit * 10
    Layout.minimumHeight: Kirigami.Units.gridUnit * 10
    Layout.preferredWidth: Kirigami.Units.gridUnit * 15 
    Layout.preferredHeight: Kirigami.Units.gridUnit * 15

    // Properties bound to configuration
    property int refreshInterval: plasmoid.configuration.refreshInterval
    property string displayText: plasmoid.configuration.displayText
    property bool showAnimation: plasmoid.configuration.showAnimation

    // Dynamic color based on theme
    property color textColor: PlasmaCore.Theme.textColor
    
    ColumnLayout {
        anchors.fill: parent
        spacing: Kirigami.Units.smallSpacing

        PlasmaComponents3.Label {
            Layout.alignment: Qt.AlignCenter
            text: displayText
            font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.5
            color: textColor
        }

        PlasmaComponents3.Slider {
            id: slider
            Layout.fillWidth: true
            from: 0
            to: 100
            value: 50
            
            onValueChanged: {
                // Example of dynamic binding
                progressBar.value = value / 100
            }
        }

        PlasmaComponents3.ProgressBar {
            id: progressBar
            Layout.fillWidth: true
            value: slider.value / 100
        }

        RowLayout {
            Layout.alignment: Qt.AlignCenter
            spacing: Kirigami.Units.smallSpacing

            PlasmaComponents3.Button {
                text: i18n("Reset")
                icon.name: "edit-reset"
                onClicked: {
                    slider.value = 50
                }
            }

            PlasmaComponents3.Button {
                text: i18n("Settings")
                icon.name: "configure"
                onClicked: {
                    plasmoid.action("configure").trigger()
                }
            }
        }
    }

    // Example animation
    Rectangle {
        id: animatedElement
        width: Kirigami.Units.gridUnit
        height: width
        radius: width/2
        color: PlasmaCore.Theme.highlightColor
        visible: showAnimation
        
        NumberAnimation on rotation {
            from: 0
            to: 360
            duration: 2000
            loops: Animation.Infinite
            running: showAnimation
        }
        
        anchors {
            right: parent.right
            bottom: parent.bottom
            margins: Kirigami.Units.smallSpacing
        }
    }
}
