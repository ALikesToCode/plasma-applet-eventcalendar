import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.kirigami 2.20 as Kirigami

PlasmoidItem {
    id: root

    // Configuration properties that will be saved
    property int refreshInterval: plasmoid.configuration.refreshInterval
    property string displayMode: plasmoid.configuration.displayMode
    property bool showNotifications: plasmoid.configuration.showNotifications

    // UI properties
    property int counter: 0
    
    Plasmoid.compactRepresentation: PlasmaComponents3.Button {
        Layout.minimumWidth: Kirigami.Units.gridUnit * 10
        Layout.minimumHeight: Kirigami.Units.gridUnit * 4
        
        text: i18n("Count: %1", counter)
        
        onClicked: {
            counter++
            if (showNotifications) {
                showCounterNotification()
            }
        }
    }

    Plasmoid.fullRepresentation: ColumnLayout {
        spacing: Kirigami.Units.smallSpacing
        
        PlasmaComponents3.Label {
            Layout.alignment: Qt.AlignHCenter
            text: i18n("Demo Plasma Widget")
            font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.5
        }
        
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: Kirigami.Units.largeSpacing
            
            PlasmaComponents3.Button {
                text: i18n("Increment")
                icon.name: "list-add"
                onClicked: counter++
            }
            
            PlasmaComponents3.Button {
                text: i18n("Reset")
                icon.name: "edit-clear"
                onClicked: counter = 0
            }
        }
        
        PlasmaComponents3.Slider {
            Layout.fillWidth: true
            from: 0
            to: 100
            value: counter
            onMoved: counter = value
        }
    }

    // Timer for periodic updates
    Timer {
        interval: refreshInterval * 1000
        running: refreshInterval > 0
        repeat: true
        onTriggered: {
            counter++
        }
    }

    function showCounterNotification() {
        PlasmaCore.Notification {
            title: i18n("Counter Updated")
            text: i18n("The counter value is now: %1", counter)
            iconName: "dialog-information"
        }
    }

    // Configuration changed handler
    Connections {
        target: plasmoid.configuration
        function onRefreshIntervalChanged() {
            refreshInterval = plasmoid.configuration.refreshInterval
        }
        function onDisplayModeChanged() {
            displayMode = plasmoid.configuration.displayMode
        }
        function onShowNotificationsChanged() {
            showNotifications = plasmoid.configuration.showNotifications
        }
    }

    Component.onCompleted: {
        // Initialize configuration values
        refreshInterval = plasmoid.configuration.refreshInterval
        displayMode = plasmoid.configuration.displayMode
        showNotifications = plasmoid.configuration.showNotifications
    }
}
