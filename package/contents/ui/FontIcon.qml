import QtQuick 2.15
import QtQuick.Layouts 1.15
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.kirigami 2.20 as Kirigami

Item {
    id: root
    
    // Expose configuration properties
    property string labelText: plasmoid.configuration.labelText
    property int sliderValue: plasmoid.configuration.sliderValue
    property color customColor: plasmoid.configuration.customColor
    
    Plasmoid.preferredRepresentation: Plasmoid.fullRepresentation
    
    // Main layout
    ColumnLayout {
        anchors.fill: parent
        spacing: Kirigami.Units.smallSpacing
        
        PlasmaComponents3.Label {
            Layout.alignment: Qt.AlignHCenter
            text: labelText
            color: PlasmaCore.Theme.textColor
        }
        
        PlasmaComponents3.Button {
            Layout.alignment: Qt.AlignHCenter
            text: i18n("Click Me")
            icon.name: "dialog-ok"
            onClicked: {
                console.log("Button clicked!")
            }
        }
        
        PlasmaComponents3.Slider {
            Layout.fillWidth: true
            from: 0
            to: 100
            value: sliderValue
            onValueChanged: {
                plasmoid.configuration.sliderValue = value
            }
        }
        
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            width: Kirigami.Units.gridUnit * 2
            height: width
            color: customColor
            border.color: PlasmaCore.Theme.textColor
            border.width: 1
            radius: width / 2
            
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    colorDialog.open()
                }
            }
        }
    }
    
    // Configuration handling
    Plasmoid.configurationRequired: false
    
    // Initial setup
    Component.onCompleted: {
        // Set default values if not configured
        if (!plasmoid.configuration.labelText) {
            plasmoid.configuration.labelText = i18n("Hello Plasma!")
        }
        if (!plasmoid.configuration.sliderValue) {
            plasmoid.configuration.sliderValue = 50
        }
        if (!plasmoid.configuration.customColor) {
            plasmoid.configuration.customColor = PlasmaCore.Theme.highlightColor
        }
    }
}
