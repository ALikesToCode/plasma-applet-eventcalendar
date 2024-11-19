import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.plasmoid 2.0
import org.kde.kirigami 2.20 as Kirigami

PlasmoidItem {
    id: root
    
    // Configuration properties
    property bool showTemperature: Plasmoid.configuration.showTemperature
    property bool showPrecipitation: Plasmoid.configuration.showPrecipitation
    property int updateInterval: Plasmoid.configuration.updateInterval
    
    // Data model
    property var weatherData: ({
        temperature: 20,
        precipitation: 0,
        condition: "sunny"
    })

    Plasmoid.backgroundHints: PlasmaCore.Types.DefaultBackground
    
    // Main layout
    contentItem: ColumnLayout {
        spacing: Kirigami.Units.smallSpacing
        
        // Weather icon
        Kirigami.Icon {
            Layout.alignment: Qt.AlignHCenter
            source: getWeatherIcon(weatherData.condition)
            implicitWidth: Kirigami.Units.iconSizes.large
            implicitHeight: Kirigami.Units.iconSizes.large
        }
        
        // Temperature display
        PlasmaComponents.Label {
            visible: showTemperature
            Layout.alignment: Qt.AlignHCenter
            text: i18n("%1°C", weatherData.temperature)
            font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.5
        }
        
        // Precipitation display
        PlasmaComponents.Label {
            visible: showPrecipitation
            Layout.alignment: Qt.AlignHCenter
            text: i18n("Precipitation: %1mm", weatherData.precipitation)
        }
        
        // Refresh button
        PlasmaComponents.Button {
            Layout.alignment: Qt.AlignHCenter
            icon.name: "view-refresh"
            text: i18n("Refresh")
            onClicked: updateWeather()
        }
    }
    
    // Timer for automatic updates
    Timer {
        interval: updateInterval * 60000 // Convert minutes to milliseconds
        running: true
        repeat: true
        onTriggered: updateWeather()
    }
    
    // Helper functions
    function getWeatherIcon(condition) {
        switch(condition.toLowerCase()) {
            case "sunny": return "weather-clear"
            case "cloudy": return "weather-clouds"
            case "rainy": return "weather-rain"
            default: return "weather-none-available"
        }
    }
    
    function updateWeather() {
        // Simulated weather update
        // In a real widget, this would fetch data from a weather service
        weatherData = {
            temperature: Math.floor(Math.random() * 30),
            precipitation: Math.random() * 10,
            condition: ["sunny", "cloudy", "rainy"][Math.floor(Math.random() * 3)]
        }
    }
    
    Component.onCompleted: {
        updateWeather()
    }
}

// Configuration form - would be in a separate config.qml file
/*
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.20 as Kirigami

Item {
    id: configRoot
    
    property alias cfg_showTemperature: showTempCheckbox.checked
    property alias cfg_showPrecipitation: showPrecipCheckbox.checked
    property alias cfg_updateInterval: updateIntervalSpinBox.value

    Kirigami.FormLayout {
        anchors.left: parent.left
        anchors.right: parent.right

        CheckBox {
            id: showTempCheckbox
            Kirigami.FormData.label: i18n("Display:")
            text: i18n("Show Temperature")
        }
        
        CheckBox {
            id: showPrecipCheckbox
            text: i18n("Show Precipitation")
        }
        
        SpinBox {
            id: updateIntervalSpinBox
            Kirigami.FormData.label: i18n("Update Interval (minutes):")
            from: 1
            to: 60
            value: 15
        }
    }
}
*/
