import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.15 as Kirigami
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components 3.0 as PC3

Plasmoid.compactRepresentation: Item {
    id: root
    
    // Plasmoid properties
    Plasmoid.backgroundHints: PlasmaCore.Types.DefaultBackground
    Plasmoid.configurationRequired: false

    // Data model for tasks
    ListModel {
        id: taskModel
        ListElement { title: "Example Task 1"; completed: false }
        ListElement { title: "Example Task 2"; completed: true }
    }

    // Main layout
    ColumnLayout {
        anchors.fill: parent
        spacing: Kirigami.Units.smallSpacing

        // Header
        PC3.Label {
            Layout.fillWidth: true
            text: i18n("Task Manager")
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
        }

        // Task list
        ListView {
            id: taskList
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: taskModel
            clip: true

            delegate: RowLayout {
                width: parent.width
                spacing: Kirigami.Units.smallSpacing

                PC3.CheckBox {
                    checked: model.completed
                    onCheckedChanged: model.completed = checked
                }

                PC3.Label {
                    text: model.title
                    Layout.fillWidth: true
                    opacity: model.completed ? 0.6 : 1.0
                    font.strikeout: model.completed
                }
            }
        }

        // Add task button
        PC3.Button {
            Layout.fillWidth: true
            text: i18n("Add Task")
            icon.name: "list-add"
            onClicked: {
                taskModel.append({
                    title: i18n("New Task"),
                    completed: false
                })
            }
        }
    }

    // Configuration
    Plasmoid.configurationInterface: Item {
        Layout.fillWidth: true
        Layout.fillHeight: true

        ColumnLayout {
            anchors.fill: parent
            spacing: Kirigami.Units.largeSpacing

            PC3.CheckBox {
                text: i18n("Show completed tasks")
                checked: Plasmoid.configuration.showCompleted
                onCheckedChanged: Plasmoid.configuration.showCompleted = checked
            }

            PC3.Slider {
                Layout.fillWidth: true
                from: 10
                to: 50
                value: Plasmoid.configuration.maxTasks
                onValueChanged: Plasmoid.configuration.maxTasks = value
            }
        }
    }

    // Theme support
    PlasmaCore.ColorScope {
        id: colorScope
        colorGroup: PlasmaCore.Theme.NormalColorGroup
    }

    // Component initialization
    Component.onCompleted: {
        // Load saved configuration
        if (Plasmoid.configuration.maxTasks) {
            taskList.model.maxTasks = Plasmoid.configuration.maxTasks
        }
    }
}
