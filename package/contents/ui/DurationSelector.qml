import QtQuick 2.15
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.20 as Kirigami
import org.kde.plasma.plasma5support 2.0 as P5Support
import org.kde.plasma.components 3.0 as PC3
import org.kde.plasma.plasmoid 2.0

ColumnLayout {
    id: root
    spacing: Kirigami.Units.smallSpacing

    property alias startDateTime: startTimeSelector.dateTime
    property alias endDateTime: endTimeSelector.dateTime
    property bool enabled: true
    property bool showTime: Plasmoid.configuration.showTime

    Plasmoid.backgroundHints: PlasmaCore.Types.DefaultBackground

    PC3.Label {
        Layout.alignment: Qt.AlignHCenter
        text: i18n("Duration Selector")
        font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.2
        color: Kirigami.Theme.textColor
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Kirigami.Units.largeSpacing

        DateTimeSelector {
            id: startTimeSelector
            Layout.fillWidth: true
            enabled: root.enabled
            showTime: root.showTime
            dateFirst: true

            onDateTimeShifted: {
                // Update end date while maintaining duration
                var shiftedEndDate = new Date(endTimeSelector.dateTime.valueOf() + deltaDateTime)
                endTimeSelector.dateTime = shiftedEndDate
            }
        }

        PC3.Label {
            text: i18n("to")
            font.weight: Font.Bold
            color: Kirigami.Theme.textColor
        }

        DateTimeSelector {
            id: endTimeSelector
            Layout.fillWidth: true
            enabled: root.enabled
            showTime: root.showTime
            dateFirst: false
        }
    }

    PC3.Button {
        Layout.alignment: Qt.AlignHCenter
        text: i18n("Reset")
        icon.name: "edit-reset"
        enabled: root.enabled
        onClicked: {
            startTimeSelector.dateTime = new Date()
            endTimeSelector.dateTime = new Date()
        }
    }

    Component.onCompleted: {
        // Initialize with current date/time
        startTimeSelector.dateTime = new Date()
        endTimeSelector.dateTime = new Date()
    }
}
