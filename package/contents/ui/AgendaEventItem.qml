import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.kirigami 2.20 as Kirigami

import "LocaleFuncs.js" as LocaleFuncs
import "Shared.js" as Shared

Kirigami.AbstractCard {
    id: root
    
    // Configuration properties
    property alias title: titleLabel.text
    property alias description: descriptionLabel.text
    property int updateInterval: plasmoid.configuration.updateInterval
    
    // Theme integration
    Kirigami.Theme.colorSet: Kirigami.Theme.View
    Kirigami.Theme.inherit: false
    
    // Layout
    contentItem: ColumnLayout {
        spacing: Kirigami.Units.smallSpacing
        
        // Header
        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing
            
            PlasmaComponents3.Label {
                id: titleLabel
                Layout.fillWidth: true
                font.weight: Font.Bold
                elide: Text.ElideRight
                color: Kirigami.Theme.textColor
            }
            
            PlasmaComponents3.Button {
                icon.name: "configure"
                onClicked: plasmoid.action("configure").trigger()
                PlasmaComponents3.ToolTip {
                    text: i18n("Configure Widget")
                }
            }
        }
        
        // Content
        PlasmaComponents3.Label {
            id: descriptionLabel
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            color: Kirigami.Theme.textColor
        }
        
        // Interactive elements
        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.largeSpacing
            
            PlasmaComponents3.Slider {
                id: valueSlider
                Layout.fillWidth: true
                from: 0
                to: 100
                value: 50
                
                onValueChanged: {
                    // Example of data binding
                    descriptionLabel.text = i18n("Current value: %1", Math.round(value))
                }
            }
            
            PlasmaComponents3.Button {
                text: i18n("Reset")
                icon.name: "edit-reset"
                onClicked: valueSlider.value = 50
            }
        }
    }
    
    // Timer for periodic updates
    Timer {
        interval: root.updateInterval * 1000
        running: true
        repeat: true
        onTriggered: {
            // Example periodic update
            console.log("Widget updated at:", new Date().toLocaleString())
        }
    }
    
    // Plasmoid configuration handling
    Connections {
        target: plasmoid.configuration
        function onUpdateIntervalChanged() {
            root.updateInterval = plasmoid.configuration.updateInterval
        }
    }
    
    Component.onCompleted: {
        // Initial setup
        title = i18n("Plasma 6 Widget Example")
        description = i18n("This is a demo widget showing Plasma 6 features")
    }
}
