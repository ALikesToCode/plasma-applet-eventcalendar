import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.15 as Kirigami
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents3

Plasmoid.Plasmoid {
    id: root
    
    // Plasmoid properties
    Plasmoid.backgroundHints: PlasmaCore.Types.DefaultBackground
    Plasmoid.switchWidth: units.gridUnit * 10
    Plasmoid.switchHeight: units.gridUnit * 10
    
    // Configuration properties bound to config values
    property int refreshInterval: Plasmoid.configuration.refreshInterval
    property string displayMode: Plasmoid.configuration.displayMode
    
    // Main content
    contentItem: ColumnLayout {
        spacing: Kirigami.Units.smallSpacing
        
        Kirigami.Heading {
            Layout.fillWidth: true
            level: 2
            text: i18n("Sample Widget")
            color: Kirigami.Theme.textColor
        }
        
        PlasmaComponents3.TextField {
            id: inputField
            Layout.fillWidth: true
            placeholderText: i18n("Enter text...")
            onTextChanged: {
                outputLabel.text = text
            }
        }
        
        PlasmaComponents3.Label {
            id: outputLabel
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            color: Kirigami.Theme.textColor
        }
        
        PlasmaComponents3.Slider {
            id: valueSlider
            Layout.fillWidth: true
            from: 0
            to: 100
            value: 50
            
            onValueChanged: {
                sliderValueLabel.text = i18n("Value: %1", Math.round(value))
            }
        }
        
        PlasmaComponents3.Label {
            id: sliderValueLabel
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: i18n("Value: 50")
            color: Kirigami.Theme.textColor
        }
        
        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            
            PlasmaComponents3.Button {
                text: i18n("Reset")
                icon.name: "edit-reset"
                onClicked: {
                    inputField.text = ""
                    valueSlider.value = 50
                }
            }
            
            PlasmaComponents3.Button {
                text: i18n("Settings")
                icon.name: "configure"
                onClicked: {
                    Plasmoid.action("configure").trigger()
                }
            }
        }
    }
    
    // Configuration dialog component
    Plasmoid.configurationRequired: false
    
    Component.onCompleted: {
        // Initialize any needed resources
        console.log("Widget initialized")
    }
    
    // Timer for periodic updates if needed
    Timer {
        interval: refreshInterval * 1000
        running: true
        repeat: true
        onTriggered: {
            // Periodic update logic
        }
    }
}
