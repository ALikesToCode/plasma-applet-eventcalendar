import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.kirigami 2.20 as Kirigami

import "../ErrorType.js" as ErrorType
import "../Shared.js" as Shared
import "../lib/Async.js" as Async
import "../lib/Requests.js" as Requests
import "../code/ColorIdMap.js" as ColorIdMap

Plasmoid.compactRepresentation: PlasmaCore.IconItem {
    source: "view-calendar"
    active: mouseArea.containsMouse
    
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: plasmoid.expanded = !plasmoid.expanded
    }
}

Plasmoid.fullRepresentation: Item {
    id: root
    
    Layout.minimumWidth: Kirigami.Units.gridUnit * 20
    Layout.minimumHeight: Kirigami.Units.gridUnit * 20
    Layout.preferredWidth: Kirigami.Units.gridUnit * 30
    Layout.preferredHeight: Kirigami.Units.gridUnit * 30

    property var session
    readonly property var calendarIdList: plasmoid.configuration.calendarIdList ? plasmoid.configuration.calendarIdList.split(',') : []

    ColumnLayout {
        anchors.fill: parent
        spacing: Kirigami.Units.smallSpacing

        PlasmaComponents.Label {
            text: i18n("Google Calendar")
            font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.2
            Layout.alignment: Qt.AlignHCenter
        }

        ListView {
            id: calendarView
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: calendarIdList
            clip: true

            delegate: Kirigami.SwipeListItem {
                contentItem: RowLayout {
                    PlasmaComponents.Label {
                        text: modelData
                        Layout.fillWidth: true
                    }
                }
            }

            PlasmaComponents.ScrollBar.vertical: PlasmaComponents.ScrollBar {}
        }

        PlasmaComponents.Button {
            text: i18n("Refresh")
            icon.name: "view-refresh"
            Layout.alignment: Qt.AlignHCenter
            onClicked: fetchGoogleAccountData()
        }
    }

    function fetchGoogleAccountData() {
        if (session && session.accessToken) {
            fetchGoogleAccountEvents(calendarIdList)
        }
    }

    // Error handling
    function showHttpError(httpCode, msg, suggestion, errorType) {
        var errorMessage = i18n("HTTP Error %1: %2", httpCode, msg)
        if (suggestion) {
            errorMessage += '\n' + suggestion
        }
        // Show error using Kirigami
        Kirigami.MessageDialog.warning(root, {
            title: i18n("Error"),
            text: errorMessage
        })
    }

    // Configuration
    Plasmoid.configurationRequired: !session || !session.accessToken
    
    Component.onCompleted: {
        fetchGoogleAccountData()
    }
}
