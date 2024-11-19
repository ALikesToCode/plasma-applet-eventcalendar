import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.kirigami 2.20 as Kirigami

Plasmoid.compactRepresentation: Item {
    id: root
    
    // Properties for configuration
    property int refreshInterval: plasmoid.configuration.refreshInterval
    property string displayText: plasmoid.configuration.displayText
    property bool showIcon: plasmoid.configuration.showIcon
    
    // Theme integration
    PlasmaCore.ColorScope {
        id: colorScope
        anchors.fill: parent
        
        ColumnLayout {
            anchors.fill: parent
            spacing: Kirigami.Units.smallSpacing
            
            // Header with icon
            RowLayout {
                Layout.fillWidth: true
                
                PlasmaCore.IconItem {
                    source: "clock"
                    visible: showIcon
                    Layout.preferredWidth: Kirigami.Units.iconSizes.small
                    Layout.preferredHeight: Kirigami.Units.iconSizes.small
                }
                
                PlasmaComponents.Label {
                    text: displayText
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignHCenter
                }
            }
            
            // Interactive elements
            PlasmaComponents.Button {
                text: i18n("Refresh")
                Layout.alignment: Qt.AlignHCenter
                onClicked: updateData()
            }
            
            PlasmaComponents.Slider {
                Layout.fillWidth: true
                from: 0
                to: 100
                value: 50
                onValueChanged: {
                    // Example of data binding
                    console.log("Slider value:", value)
                }
            }
        }
    }
    
    // Business logic
    Timer {
        interval: refreshInterval * 1000
        running: true
        repeat: true
        onTriggered: updateData()
    }
    
    function updateData() {
        // Example update function
        console.log("Updating widget data...")
    }
    
    Component.onCompleted: {
        updateData()
    }
}

// Configuration properties
Plasmoid.configurationRequired: false

Plasmoid.configuration: {
    "refreshInterval": {
        "type": "int",
        "default": 60,
        "label": i18n("Refresh Interval (seconds)")
    },
    "displayText": {
        "type": "string",
        "default": i18n("My Widget"),
        "label": i18n("Display Text")
    },
    "showIcon": {
        "type": "bool",
        "default": true,
        "label": i18n("Show Icon")
    }
}
