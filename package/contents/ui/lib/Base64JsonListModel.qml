import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.kirigami 2.20 as Kirigami

Plasmoid {
    id: root
    
    // Plasmoid properties
    property int refreshInterval: plasmoid.configuration.refreshInterval
    property string displayText: plasmoid.configuration.displayText
    
    // Main layout
    Plasmoid.fullRepresentation: ColumnLayout {
        spacing: Kirigami.Units.smallSpacing
        
        PlasmaComponents.Label {
            Layout.alignment: Qt.AlignHCenter
            text: root.displayText
            font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.2
            color: Kirigami.Theme.textColor
        }
        
        PlasmaComponents.Button {
            Layout.alignment: Qt.AlignHCenter
            text: i18n("Click Me")
            icon.name: "dialog-ok"
            onClicked: {
                root.displayText = i18n("Button clicked at: %1", new Date().toLocaleString())
            }
        }
        
        PlasmaComponents.Slider {
            Layout.fillWidth: true
            from: 0
            to: 100
            value: 50
            onValueChanged: {
                console.log("Slider value:", value)
            }
        }
    }
    
    // Configuration page
    Plasmoid.configurationRequired: false
    
    Plasmoid.configuration: PlasmaCore.ConfigModel {
        ConfigCategory {
            name: i18n("General")
            icon: "configure"
            source: "configGeneral.qml"
        }
    }
    
    // Timer for periodic updates
    Timer {
        interval: root.refreshInterval * 1000
        running: true
        repeat: true
        onTriggered: {
            // Periodic update logic
            console.log("Timer update at:", new Date().toLocaleString())
        }
    }
    
    // Component lifecycle
    Component.onCompleted: {
        console.log("Plasmoid initialized")
    }
}
