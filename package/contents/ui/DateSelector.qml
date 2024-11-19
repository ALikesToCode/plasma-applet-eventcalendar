import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root
    
    // Plasmoid properties
    Plasmoid.backgroundHints: PlasmaCore.Types.DefaultBackground
    Plasmoid.configurationRequired: false
    
    // Properties for date handling
    property var currentDate: new Date()
    property string dateFormat: Qt.locale().dateFormat(Locale.ShortFormat)
    
    // Signals for date changes
    signal dateTimeShifted(date oldDateTime, int deltaDateTime, date newDateTime)
    signal dateSelected(date newDateTime)
    
    // Main layout
    contentItem: ColumnLayout {
        spacing: Kirigami.Units.smallSpacing
        
        PlasmaComponents.Label {
            Layout.alignment: Qt.AlignHCenter
            text: i18n("Select Date")
            font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.2
        }
        
        PlasmaComponents.TextField {
            id: dateField
            Layout.fillWidth: true
            text: currentDate.toLocaleDateString(Qt.locale(), dateFormat)
            
            onTextEdited: {
                let newDate = Date.fromLocaleDateString(Qt.locale(), text, dateFormat)
                if (!isNaN(newDate)) {
                    setDateTime(newDate)
                }
            }
            
            onPressed: datePopup.open()
        }
        
        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing
            
            PlasmaComponents.Button {
                Layout.fillWidth: true
                text: i18n("Previous")
                icon.name: "go-previous"
                onClicked: {
                    let oldDate = new Date(currentDate)
                    let newDate = new Date(currentDate)
                    newDate.setDate(newDate.getDate() - 1)
                    setDateTime(newDate)
                }
            }
            
            PlasmaComponents.Button {
                Layout.fillWidth: true
                text: i18n("Today")
                icon.name: "go-jump-today"
                onClicked: setDateTime(new Date())
            }
            
            PlasmaComponents.Button {
                Layout.fillWidth: true
                text: i18n("Next")
                icon.name: "go-next"
                onClicked: {
                    let oldDate = new Date(currentDate)
                    let newDate = new Date(currentDate)
                    newDate.setDate(newDate.getDate() + 1)
                    setDateTime(newDate)
                }
            }
        }
    }
    
    // Date selection popup
    QQC.Popup {
        id: datePopup
        x: (parent.width - width) / 2
        y: parent.height
        
        contentItem: Calendar {
            id: calendar
            selectedDate: root.currentDate
            
            onSelectedDateChanged: {
                setDateTime(selectedDate)
                datePopup.close()
            }
        }
        
        background: Rectangle {
            color: Kirigami.Theme.backgroundColor
            border.color: Kirigami.Theme.textColor
            border.width: 1
            radius: 2
            
            layer.enabled: true
            layer.effect: PlasmaCore.DropShadow {
                radius: 8
                samples: 16
                color: Qt.rgba(0, 0, 0, 0.3)
                horizontalOffset: 0
                verticalOffset: 2
            }
        }
    }
    
    // Date handling functions
    function setDateTime(dt) {
        let oldDateTime = new Date(currentDate)
        let newDateTime = new Date(dt)
        
        // Preserve time when changing date
        newDateTime.setHours(oldDateTime.getHours())
        newDateTime.setMinutes(oldDateTime.getMinutes())
        
        let deltaDateTime = newDateTime.valueOf() - oldDateTime.valueOf()
        currentDate = newDateTime
        dateTimeShifted(oldDateTime, deltaDateTime, newDateTime)
        dateSelected(newDateTime)
    }
    
    // Configuration handling
    Plasmoid.configurationRequired: false
    
    Component.onCompleted: {
        // Initialize with current date
        setDateTime(new Date())
    }
}
