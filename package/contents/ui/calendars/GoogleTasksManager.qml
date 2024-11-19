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
    Plasmoid.backgroundHints: PlasmaCore.Types.DefaultBackground
    Plasmoid.switchWidth: units.gridUnit * 10
    Plasmoid.switchHeight: units.gridUnit * 10

    // Configuration properties
    property int refreshInterval: plasmoid.configuration.refreshInterval
    property bool showNotifications: plasmoid.configuration.showNotifications
    property string apiKey: plasmoid.configuration.apiKey

    // Internal properties
    property var taskList: []
    property bool loading: false

    // Main layout
    Plasmoid.fullRepresentation: ColumnLayout {
        anchors.fill: parent
        spacing: Kirigami.Units.smallSpacing

        // Header
        PlasmaComponents.Label {
            Layout.fillWidth: true
            text: i18n("Tasks")
            font.pointSize: theme.defaultFont.pointSize * 1.2
            font.weight: Font.Bold
            color: theme.textColor
        }

        // Task list
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ListView {
                model: root.taskList
                delegate: TaskDelegate {}
                clip: true
                
                PlasmaComponents.BusyIndicator {
                    anchors.centerIn: parent
                    running: root.loading
                    visible: root.loading
                }
            }
        }

        // Add task button
        PlasmaComponents.Button {
            Layout.fillWidth: true
            text: i18n("Add Task")
            icon.name: "list-add"
            onClicked: addNewTask()
        }
    }

    // Task delegate component
    component TaskDelegate: ItemDelegate {
        width: ListView.view.width
        height: taskLayout.implicitHeight + 2 * Kirigami.Units.smallSpacing

        RowLayout {
            id: taskLayout
            anchors {
                fill: parent
                margins: Kirigami.Units.smallSpacing
            }

            PlasmaComponents.CheckBox {
                checked: model.completed
                onToggled: toggleTaskComplete(model.index)
            }

            PlasmaComponents.Label {
                Layout.fillWidth: true
                text: model.title
                color: theme.textColor
                opacity: model.completed ? 0.6 : 1.0
                font.strikeout: model.completed
            }

            PlasmaComponents.Button {
                icon.name: "edit-delete"
                onClicked: deleteTask(model.index)
                PlasmaComponents.ToolTip {
                    text: i18n("Delete task")
                }
            }
        }
    }

    // Configuration
    Plasmoid.configurationRequired: !apiKey
    
    // Configuration page component
    ConfigurationPage {
        id: configPage
        
        property alias cfg_refreshInterval: refreshIntervalSpinBox.value
        property alias cfg_showNotifications: notificationsCheckBox.checked
        property alias cfg_apiKey: apiKeyField.text

        Kirigami.FormLayout {
            QQC2.SpinBox {
                id: refreshIntervalSpinBox
                Kirigami.FormData.label: i18n("Refresh interval (minutes):")
                from: 1
                to: 60
            }

            QQC2.CheckBox {
                id: notificationsCheckBox
                text: i18n("Show notifications")
            }

            QQC2.TextField {
                id: apiKeyField
                Kirigami.FormData.label: i18n("API Key:")
                echoMode: TextInput.Password
            }
        }
    }

    // Business logic functions
    function addNewTask() {
        // Implementation
    }

    function toggleTaskComplete(index) {
        // Implementation
    }

    function deleteTask(index) {
        // Implementation
    }

    // Lifecycle
    Component.onCompleted: {
        refreshTasks()
    }

    Timer {
        interval: refreshInterval * 60 * 1000
        running: true
        repeat: true
        onTriggered: refreshTasks()
    }

    function refreshTasks() {
        root.loading = true
        // Implementation to fetch tasks
        root.loading = false
    }
}
