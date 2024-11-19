import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.kirigami 2.20 as Kirigami

Item {
    id: root
    
    // Expose configuration properties
    property alias showTitle: plasmoid.configuration.showTitle
    property alias titleText: plasmoid.configuration.titleText
    property alias sliderValue: plasmoid.configuration.sliderValue
    
    // Main layout
    ColumnLayout {
        anchors.fill: parent
        spacing: Kirigami.Units.smallSpacing

        // Title section
        PlasmaComponents3.Label {
            Layout.fillWidth: true
            text: showTitle ? titleText : ""
            visible: showTitle
            horizontalAlignment: Text.AlignHCenter
            font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.2
            color: Kirigami.Theme.textColor
        }

        // Interactive slider
        PlasmaComponents3.Slider {
            Layout.fillWidth: true
            from: 0
            to: 100
            value: sliderValue
            onValueChanged: {
                plasmoid.configuration.sliderValue = value
            }
        }

        // Action button
        PlasmaComponents3.Button {
            Layout.alignment: Qt.AlignHCenter
            text: i18n("Click Me")
            icon.name: "dialog-ok"
            onClicked: {
                // Example action
                console.log("Button clicked, slider value:", sliderValue)
            }
        }
    }

    // Configuration page definition
    Plasmoid.configurationRequired: false
    Plasmoid.configurationItem: Item {
        property alias cfg_showTitle: showTitleCheckbox.checked
        property alias cfg_titleText: titleTextField.text
        property alias cfg_sliderValue: sliderSpinBox.value

        ColumnLayout {
            spacing: Kirigami.Units.smallSpacing

            PlasmaComponents3.CheckBox {
                id: showTitleCheckbox
                text: i18n("Show Title")
            }

            PlasmaComponents3.TextField {
                id: titleTextField
                Layout.fillWidth: true
                placeholderText: i18n("Enter title text...")
                enabled: showTitleCheckbox.checked
            }

            PlasmaComponents3.SpinBox {
                id: sliderSpinBox
                from: 0
                to: 100
                Layout.fillWidth: true
            }
        }
    }

    // Component initialization
    Component.onCompleted: {
        // Initial setup if needed
        if (!plasmoid.configuration.hasOwnProperty("showTitle")) {
            plasmoid.configuration.showTitle = true
        }
        if (!plasmoid.configuration.hasOwnProperty("titleText")) {
            plasmoid.configuration.titleText = i18n("My Widget")
        }
        if (!plasmoid.configuration.hasOwnProperty("sliderValue")) {
            plasmoid.configuration.sliderValue = 50
        }
    }
}
