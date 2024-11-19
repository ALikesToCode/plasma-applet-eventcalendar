import QtQuick 2.15
import QtQuick.Layouts 1.15
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.kirigami 2.20 as Kirigami

Item {
    id: root

    // Expose configuration properties
    readonly property int refreshInterval: plasmoid.configuration.refreshInterval
    readonly property string displayText: plasmoid.configuration.displayText
    readonly property bool showIcon: plasmoid.configuration.showIcon
    
    // Internal state properties
    property int clickCount: 0
    property real sliderValue: 0.5
    
    Plasmoid.fullRepresentation: ColumnLayout {
        anchors.fill: parent
        spacing: Kirigami.Units.smallSpacing

        PlasmaComponents3.Label {
            Layout.alignment: Qt.AlignHCenter
            text: root.displayText
            font: Kirigami.Theme.defaultFont
            color: Kirigami.Theme.textColor
        }

        PlasmaComponents3.Button {
            Layout.alignment: Qt.AlignHCenter
            text: i18n("Clicked: %1", root.clickCount)
            icon.name: root.showIcon ? "dialog-ok" : ""
            onClicked: root.clickCount++
        }

        PlasmaComponents3.Slider {
            Layout.fillWidth: true
            from: 0
            to: 100
            value: root.sliderValue * 100
            onMoved: root.sliderValue = value / 100
        }

        PlasmaComponents3.ProgressBar {
            Layout.fillWidth: true
            from: 0
            to: 1
            value: root.sliderValue
        }
    }

    Plasmoid.preferredRepresentation: Plasmoid.fullRepresentation

    // Update timer
    Timer {
        id: updateTimer
        interval: root.refreshInterval * 1000
        running: true
        repeat: true
        onTriggered: {
            // Perform periodic updates here
            console.log("Timer update, slider value:", root.sliderValue)
        }
    }

    // Configuration changed handlers
    Connections {
        target: plasmoid.configuration
        function onRefreshIntervalChanged() {
            updateTimer.interval = root.refreshInterval * 1000
        }
        function onDisplayTextChanged() {
            console.log("Display text updated:", root.displayText)
        }
        function onShowIconChanged() {
            console.log("Show icon setting changed:", root.showIcon)
        }
    }

    // Theme change handler
    Connections {
        target: Kirigami.Theme
        function onColorSetChanged() {
            console.log("Theme changed to:", Kirigami.Theme.colorSet)
        }
    }

    Component.onCompleted: {
        // Initialization code
        console.log("Widget initialized")
        updateTimer.start()
    }
}
