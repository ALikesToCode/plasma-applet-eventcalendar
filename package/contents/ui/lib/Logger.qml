// Version 3

import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.kirigami 2.20 as Kirigami

Plasmoid {
    id: root
    
    // Plasmoid properties
    property int refreshInterval: plasmoid.configuration.refreshInterval
    property string displayText: plasmoid.configuration.displayText
    
    // Main layout
    Plasmoid.fullRepresentation: ColumnLayout {
        spacing: Kirigami.Units.smallSpacing
        
        PlasmaComponents3.Label {
            Layout.alignment: Qt.AlignHCenter
            text: displayText
            font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.2
            color: Kirigami.Theme.textColor
        }
        
        PlasmaComponents3.Button {
            Layout.alignment: Qt.AlignHCenter
            text: i18n("Click Me")
            icon.name: "dialog-ok"
            onClicked: {
                displayText = i18n("Button clicked at: %1", new Date().toLocaleString())
            }
        }
        
        PlasmaComponents3.Slider {
            Layout.fillWidth: true
            from: 1
            to: 60
            value: refreshInterval
            onValueChanged: {
                plasmoid.configuration.refreshInterval = value
            }
        }
    }
    
    // Configuration properties
    Plasmoid.configurationRequired: false
    
    // Configuration page
    Plasmoid.configuration: {
        "refreshInterval": 30,
        "displayText": i18n("Hello Plasma 6!")
    }
    
    // Timer for periodic updates
    Timer {
        interval: refreshInterval * 1000
        running: true
        repeat: true
        onTriggered: {
            // Update logic here
            console.log("Timer triggered at:", new Date().toLocaleString())
        }
    }
    
    // Logging functions
    function debug() {
        if (plasmoid.configuration.debugMode) {
            var args = Array.from(arguments)
            args.unshift('[Debug]')
            console.debug.apply(console, args)
        }
    }
    
    function log() {
        var args = Array.from(arguments)
        args.unshift('[Info]')
        console.log.apply(console, args)
    }
    
    function logError() {
        var args = Array.from(arguments)
        args.unshift('[Error]')
        console.error.apply(console, args)
    }
    
    Component.onCompleted: {
        log("Plasmoid initialized")
    }
}
