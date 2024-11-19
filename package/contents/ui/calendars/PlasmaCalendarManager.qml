import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.20 as Kirigami
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore

PlasmoidItem {
    id: root

    // Plasmoid properties
    Plasmoid.backgroundHints: PlasmaCore.Types.DefaultBackground
    Plasmoid.switchWidth: units.gridUnit * 10
    Plasmoid.switchHeight: units.gridUnit * 10

    // Properties bound to configuration
    property int refreshInterval: plasmoid.configuration.refreshInterval
    property string displayText: plasmoid.configuration.displayText
    property bool showIcon: plasmoid.configuration.showIcon

    // Main layout
    contentItem: ColumnLayout {
        spacing: Kirigami.Units.smallSpacing

        PlasmaComponents.Label {
            Layout.alignment: Qt.AlignHCenter
            text: displayText
            font.pointSize: theme.defaultFont.pointSize * 1.2
            color: theme.textColor
        }

        PlasmaComponents.Button {
            Layout.alignment: Qt.AlignHCenter
            icon.name: "view-refresh"
            text: i18n("Refresh")
            onClicked: updateData()
        }

        QQC2.Slider {
            Layout.fillWidth: true
            from: 0
            to: 100
            value: 50
            onValueChanged: {
                // Example of dynamic update
                console.log("Slider value:", value)
            }
        }

        PlasmaComponents.CheckBox {
            text: i18n("Enable Feature")
            checked: showIcon
            onCheckedChanged: {
                plasmoid.configuration.showIcon = checked
            }
        }
    }

    // Configuration property definitions
    property QtObject cfg_refreshInterval: QtObject {
        property int value: refreshInterval
    }

    property QtObject cfg_displayText: QtObject {
        property string value: displayText
    }

    property QtObject cfg_showIcon: QtObject {
        property bool value: showIcon
    }

    // Configuration page component
    Plasmoid.configurationRequired: false
    
    Component.onCompleted: {
        updateData()
    }

    function updateData() {
        // Example function to update widget data
        console.log("Updating widget data...")
    }

    // Timer for periodic updates
    Timer {
        interval: refreshInterval * 1000
        running: true
        repeat: true
        onTriggered: updateData()
    }
}
