import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.kirigami 2.20 as Kirigami

Plasmoid.compactRepresentation: PlasmaComponents3.Label {
    id: root
    
    property string configuredText: plasmoid.configuration.displayText
    property string configuredUrl: plasmoid.configuration.linkUrl
    
    text: "<a href='" + configuredUrl + "'>" + configuredText + "</a>"
    textFormat: Text.RichText
    
    // Use Kirigami theme colors for better integration
    color: Kirigami.Theme.textColor
    linkColor: Kirigami.Theme.highlightColor
    
    // Handle link activation
    onLinkActivated: Qt.openUrlExternally(link)
    
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
        
        // Add hover effect
        hoverEnabled: true
        onEntered: parent.font.underline = true
        onExited: parent.font.underline = false
    }
    
    // Example of dynamic binding
    Connections {
        target: plasmoid.configuration
        function onDisplayTextChanged() {
            root.text = "<a href='" + configuredUrl + "'>" + configuredText + "</a>"
        }
        function onLinkUrlChanged() {
            root.text = "<a href='" + configuredUrl + "'>" + configuredText + "</a>"
        }
    }
}
