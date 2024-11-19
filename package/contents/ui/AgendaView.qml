import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami 2.20 as Kirigami

Item {
    id: root
    
    // Plasmoid properties
    Plasmoid.backgroundHints: PlasmaCore.Types.DefaultBackground
    Plasmoid.switchWidth: units.gridUnit * 10
    Plasmoid.switchHeight: units.gridUnit * 10

    // Config properties bound to plasmoid configuration
    property int refreshInterval: plasmoid.configuration.refreshInterval
    property string displayMode: plasmoid.configuration.displayMode
    property bool showDetails: plasmoid.configuration.showDetails

    // Theme integration
    property color textColor: PlasmaCore.Theme.textColor
    property color backgroundColor: PlasmaCore.Theme.backgroundColor
    property color highlightColor: PlasmaCore.Theme.highlightColor

    // Example data model
    ListModel {
        id: dataModel
        ListElement { name: "Item 1"; value: 50 }
        ListElement { name: "Item 2"; value: 75 }
        ListElement { name: "Item 3"; value: 25 }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Kirigami.Units.smallSpacing

        Kirigami.Heading {
            Layout.fillWidth: true
            text: i18n("Example Widget")
            level: 2
            color: root.textColor
        }

        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: dataModel
            clip: true
            
            delegate: Kirigami.BasicListItem {
                width: parent.width
                label: model.name
                
                contentItem: RowLayout {
                    spacing: Kirigami.Units.smallSpacing
                    
                    Label {
                        text: model.name
                        color: root.textColor
                    }
                    
                    Slider {
                        Layout.fillWidth: true
                        value: model.value
                        from: 0
                        to: 100
                        onValueChanged: dataModel.setProperty(index, "value", value)
                    }
                    
                    Label {
                        text: Math.round(model.value) + "%"
                        color: root.textColor
                    }
                }
            }
        }

        Button {
            Layout.alignment: Qt.AlignHCenter
            text: i18n("Refresh")
            icon.name: "view-refresh"
            
            onClicked: {
                // Example refresh action
                console.log("Refreshing widget data...")
            }
        }
    }

    // Timer for periodic updates
    Timer {
        interval: root.refreshInterval * 1000
        running: true
        repeat: true
        onTriggered: {
            // Periodic update logic
            console.log("Performing periodic update...")
        }
    }

    // Example of handling configuration changes
    Connections {
        target: plasmoid.configuration
        
        function onRefreshIntervalChanged() {
            console.log("Refresh interval changed to:", refreshInterval)
        }
        
        function onDisplayModeChanged() {
            console.log("Display mode changed to:", displayMode)
        }
    }

    Component.onCompleted: {
        // Initialization logic
        console.log("Widget initialized")
    }
}
