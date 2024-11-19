import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami 2.20 as Kirigami

Plasmoid.Planar {
    id: root
    
    // Plasmoid configuration properties bound to config values
    property int sliderValue: plasmoid.configuration.sliderValue
    property string textValue: plasmoid.configuration.textValue
    property bool toggleValue: plasmoid.configuration.toggleValue

    // Main layout container
    ColumnLayout {
        anchors.fill: parent
        spacing: Kirigami.Units.smallSpacing

        // Header with title
        Kirigami.Heading {
            Layout.fillWidth: true
            text: i18n("Example Plasma Widget")
            level: 2
            color: PlasmaCore.Theme.textColor
        }

        // Interactive slider
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            Kirigami.Label {
                text: i18n("Slider Value: %1", sliderValue)
                color: PlasmaCore.Theme.textColor
            }

            Slider {
                Layout.fillWidth: true
                from: 0
                to: 100
                value: sliderValue
                onValueChanged: plasmoid.configuration.sliderValue = value
            }
        }

        // Text input field
        TextField {
            Layout.fillWidth: true
            placeholderText: i18n("Enter text...")
            text: textValue
            onTextChanged: plasmoid.configuration.textValue = text
            color: PlasmaCore.Theme.textColor
            background: Rectangle {
                color: PlasmaCore.Theme.backgroundColor
                border.color: PlasmaCore.Theme.highlightColor
                radius: 4
            }
        }

        // Toggle switch
        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.largeSpacing

            Kirigami.Label {
                text: i18n("Toggle State:")
                color: PlasmaCore.Theme.textColor
            }

            Switch {
                checked: toggleValue
                onCheckedChanged: plasmoid.configuration.toggleValue = checked
            }
        }

        // Action button
        Button {
            Layout.fillWidth: true
            text: i18n("Click Me")
            icon.name: "dialog-ok"
            
            onClicked: {
                // Example of dynamic update
                plasmoid.configuration.textValue = i18n("Button clicked at: %1", new Date().toLocaleString())
            }
        }

        // Spacer
        Item {
            Layout.fillHeight: true
        }

        // Status footer
        Kirigami.Label {
            Layout.fillWidth: true
            text: i18n("Status: %1", toggleValue ? i18n("Active") : i18n("Inactive"))
            horizontalAlignment: Text.AlignRight
            color: toggleValue ? PlasmaCore.Theme.positiveTextColor : PlasmaCore.Theme.neutralTextColor
            font.italic: true
        }
    }

    // Component initialization
    Component.onCompleted: {
        // Set default values if not already set
        if (!plasmoid.configuration.sliderValue) {
            plasmoid.configuration.sliderValue = 50
        }
        if (!plasmoid.configuration.textValue) {
            plasmoid.configuration.textValue = i18n("Default Text")
        }
    }
}
