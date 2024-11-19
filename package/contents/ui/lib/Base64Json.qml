import QtQuick 2.15
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.plasma.plasmoid 2.0
import org.kde.kirigami 2.20 as Kirigami

Item {
    id: root
    
    // Plasmoid configuration properties
    property string configKey
    readonly property string configValue: plasmoid.configuration[configKey]
    property var value: null

    // Layout for the widget
    Plasmoid.fullRepresentation: ColumnLayout {
        spacing: Kirigami.Units.smallSpacing
        
        PlasmaComponents3.Label {
            text: i18n("Base64 JSON Widget")
            font.bold: true
            Layout.alignment: Qt.AlignHCenter
        }
        
        PlasmaComponents3.TextArea {
            id: jsonDisplay
            text: value ? JSON.stringify(value, null, 2) : ""
            readOnly: true
            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.gridUnit * 6
            background: Rectangle {
                color: Kirigami.Theme.backgroundColor
                border.color: Kirigami.Theme.textColor
                opacity: 0.1
                radius: 4
            }
        }
        
        PlasmaComponents3.Button {
            text: i18n("Update")
            icon.name: "document-save"
            Layout.alignment: Qt.AlignHCenter
            onClicked: serialize()
        }
    }

    // Configuration change handler
    onConfigValueChanged: deserialize()

    // Data handling functions
    function deserialize() {
        try {
            if (configValue) {
                var s = JSON.parse(Qt.atob(configValue))
                value = s
            }
        } catch (e) {
            console.error("Failed to deserialize:", e)
            value = null
        }
    }

    function serialize() {
        try {
            var v = Qt.btoa(JSON.stringify(value))
            plasmoid.configuration[configKey] = v
        } catch (e) {
            console.error("Failed to serialize:", e)
        }
    }

    Component.onCompleted: {
        deserialize()
    }
}
