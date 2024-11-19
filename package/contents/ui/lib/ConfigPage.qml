// Version 6

import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.kirigami 2.20 as Kirigami
import org.kde.plasma.core 2.0 as PlasmaCore

Item {
    id: page
    Layout.fillWidth: true
    default property alias _contentChildren: content.data
    implicitHeight: content.implicitHeight

    // Main content area using Kirigami theme colors
    ColumnLayout {
        id: content
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: Kirigami.Units.largeSpacing
        }
        spacing: Kirigami.Units.smallSpacing

        // Theme-aware content
        Kirigami.Theme.colorSet: Kirigami.Theme.View
        Kirigami.Theme.inherit: false

        // Handle layout cleanup properly
        Component.onDestruction: {
            while (children.length > 0) {
                children[children.length - 1].parent = page
            }
        }
    }

    property alias showAppletVersion: appletVersionLoader.active
    
    // Version info with proper theming
    Loader {
        id: appletVersionLoader
        active: false
        visible: active
        source: "AppletVersion.qml"
        anchors {
            right: parent.right
            bottom: parent.top
            margins: Kirigami.Units.smallSpacing
        }

        // Ensure proper theme inheritance
        Kirigami.Theme.colorSet: Kirigami.Theme.Window
        Kirigami.Theme.inherit: false
    }

    // Add theme change handling
    Connections {
        target: PlasmaCore.Theme
        function onThemeChanged() {
            // Trigger any necessary theme-related updates
            content.Layout.invalidate()
        }
    }
}
