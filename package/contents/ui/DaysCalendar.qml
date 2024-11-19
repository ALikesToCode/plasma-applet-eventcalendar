/*
 * SPDX-FileCopyrightText: 2024 KDE Community
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15 as QQC2

import org.kde.kirigami 2.20 as Kirigami
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core as PlasmaCore

Plasmoid.backgroundHints: PlasmaCore.Types.DefaultBackground

Item {
    id: root

    Plasmoid.title: i18n("Example Widget")
    Plasmoid.icon: "applications-system"
    
    // Example property that can be configured
    property int updateInterval: Plasmoid.configuration.updateInterval
    property string displayText: Plasmoid.configuration.displayText
    
    // Example of dynamic data binding
    property int clickCount: 0
    
    Layout.minimumWidth: Kirigami.Units.gridUnit * 10
    Layout.minimumHeight: Kirigami.Units.gridUnit * 6
    Layout.preferredWidth: Kirigami.Units.gridUnit * 15
    Layout.preferredHeight: Kirigami.Units.gridUnit * 10

    ColumnLayout {
        anchors.fill: parent
        spacing: Kirigami.Units.smallSpacing

        PlasmaComponents.Label {
            Layout.alignment: Qt.AlignHCenter
            text: root.displayText
            font.pointSize: theme.defaultFont.pointSize * 1.2
            color: theme.textColor
        }

        PlasmaComponents.Button {
            Layout.alignment: Qt.AlignHCenter
            text: i18n("Clicked: %1", root.clickCount)
            icon.name: "checkmark"
            onClicked: {
                root.clickCount++
            }
        }

        PlasmaComponents.Slider {
            Layout.fillWidth: true
            from: 0
            to: 100
            value: 50
            
            onMoved: {
                // Example of handling user interaction
                console.log("Slider value:", value)
            }
        }

        Item {
            Layout.fillHeight: true
        }
    }

    Timer {
        interval: root.updateInterval * 1000
        running: true
        repeat: true
        onTriggered: {
            // Example periodic update
            console.log("Timer update")
        }
    }
}
