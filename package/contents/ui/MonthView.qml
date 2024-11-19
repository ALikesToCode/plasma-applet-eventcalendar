/*
 * SPDX-FileCopyrightText: 2024 Your Name <your.email@example.com>
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PC3
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore

PlasmoidItem {
    id: root

    // Plasmoid properties
    Plasmoid.backgroundHints: PlasmaCore.Types.DefaultBackground
    Plasmoid.configurationRequired: false

    // Properties for data binding
    property int counter: 0
    property bool isDarkMode: PlasmaCore.Theme.darkMode
    property string displayText: plasmoid.configuration.displayText || i18n("Hello Plasma!")

    // Main layout
    contentItem: ColumnLayout {
        spacing: Kirigami.Units.smallSpacing

        // Header
        PC3.Label {
            Layout.alignment: Qt.AlignHCenter
            text: displayText
            font.pointSize: plasmoid.configuration.fontSize
            color: PlasmaCore.Theme.textColor
        }

        // Counter display
        PC3.Label {
            Layout.alignment: Qt.AlignHCenter
            text: i18n("Count: %1", counter)
            color: PlasmaCore.Theme.textColor
        }

        // Interactive button
        PC3.Button {
            Layout.alignment: Qt.AlignHCenter
            text: i18n("Increment")
            icon.name: "list-add"
            onClicked: counter++
        }

        // Theme indicator
        PC3.Label {
            Layout.alignment: Qt.AlignHCenter
            text: isDarkMode ? i18n("Dark Theme") : i18n("Light Theme")
            color: PlasmaCore.Theme.textColor
        }

        // Slider for demonstration
        PC3.Slider {
            Layout.fillWidth: true
            from: 0
            to: 100
            value: 50
            onValueChanged: {
                // Example of dynamic update
                console.log("Slider value:", value)
            }
        }
    }

    // Configuration property bindings
    Connections {
        target: plasmoid.configuration
        function onDisplayTextChanged() {
            displayText = plasmoid.configuration.displayText
        }
        function onFontSizeChanged() {
            // Handle font size changes
        }
    }

    // Theme change handling
    Connections {
        target: PlasmaCore.Theme
        function onColorSchemeChanged() {
            // Update theme-dependent properties
            isDarkMode = PlasmaCore.Theme.darkMode
        }
    }

    Component.onCompleted: {
        // Initialization code
        console.log("Plasmoid initialized")
    }
}
