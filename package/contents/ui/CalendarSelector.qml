import QtQuick 2.15
import QtQuick.Layouts 1.15
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.kirigami 2.20 as Kirigami

Plasmoid.fullRepresentation: Item {
    id: root
    
    Layout.minimumWidth: Kirigami.Units.gridUnit * 20
    Layout.minimumHeight: Kirigami.Units.gridUnit * 15
    
    // Configuration properties bound to plasmoid.configuration
    property int refreshInterval: plasmoid.configuration.refreshInterval
    property string displayStyle: plasmoid.configuration.displayStyle
    
    ColumnLayout {
        anchors.fill: parent
        spacing: Kirigami.Units.smallSpacing

        PlasmaComponents3.Label {
            Layout.alignment: Qt.AlignHCenter
            text: i18n("Calendar Widget")
            font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.5
            color: Kirigami.Theme.textColor
        }

        PlasmaComponents3.ComboBox {
            id: calendarSelector
            Layout.fillWidth: true
            model: [
                { text: i18n("[No Calendars]") }
            ]
            textRole: "text"

            readonly property var selectedCalendar: currentIndex >= 0 ? model[currentIndex] : null
            readonly property var selectedCalendarId: selectedCalendar ? selectedCalendar.id : null
            readonly property bool selectedIsTasklist: selectedCalendar ? selectedCalendar.isTasklist : false

            onCurrentIndexChanged: {
                if (selectedCalendar) {
                    updateDisplay()
                }
            }
        }

        PlasmaComponents3.Button {
            Layout.alignment: Qt.AlignHCenter
            text: i18n("Refresh")
            icon.name: "view-refresh"
            onClicked: populate(calendarList, selectedCalendarId)
        }

        function populate(calendarList, initialCalendarId) {
            var list = []
            var selectedIndex = 0
            calendarList.forEach(function(calendar) {
                var canEditCalendar = calendar.accessRole === 'writer' || calendar.accessRole === 'owner'
                var isSelected = calendar.id === initialCalendarId

                if (isSelected) {
                    selectedIndex = list.length
                }

                if (canEditCalendar || isSelected) {
                    list.push({
                        'id': calendar.id,
                        'text': calendar.summary,
                        'backgroundColor': calendar.backgroundColor,
                        'isTasklist': calendar.isTasklist,
                    })
                }
            })
            if (list.length === 0) {
                list.push({ text: i18n("[No Calendars]") })
            }
            calendarSelector.model = list
            calendarSelector.currentIndex = selectedIndex
        }

        function updateDisplay() {
            // Update the display based on selected calendar
            // This would be implemented based on specific requirements
        }
    }

    Component.onCompleted: {
        // Initial setup
        populate([], null)
    }
}
