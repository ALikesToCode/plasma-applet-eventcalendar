import QtQuick 2.15
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

import org.kde.plasma.core as PlasmaCore

GridLayout {
    id: dateTimeSelector
    property var dateTime: new Date()
    property bool enabled: true
    property bool showTime: true
    property alias dateFormat: dateSelector.dateFormat
    property alias timeFormat: timeSelector.timeFormat
    property bool dateFirst: true
    columns: 2
    columnSpacing: Kirigami.Units.smallSpacing
    readonly property int minimumWidth: dateSelector.implicitWidth + columnSpacing + timeSelector.implicitWidth

    signal dateTimeShifted(date oldDateTime, int deltaDateTime, date newDateTime)
    onDateTimeShifted: {
        dateTimeSelector.dateTime = newDateTime
    }

    DateSelector {
        id: dateSelector
        enabled: dateTimeSelector.enabled
        Layout.column: dateTimeSelector.dateFirst ? 0 : 1

        dateTime: dateTimeSelector.dateTime
        dateFormat: i18nc("event editor date format", "d MMM, yyyy")

        onDateTimeShifted: {
            dateTimeSelector.dateTimeShifted(oldDateTime, deltaDateTime, newDateTime)
        }
    }

    TimeSelector {
        id: timeSelector
        enabled: dateTimeSelector.enabled && dateTimeSelector.showTime
        visible: dateTimeSelector.showTime
        Layout.column: dateTimeSelector.dateFirst ? 1 : 0

        dateTime: dateTimeSelector.dateTime

        onDateTimeShifted: {
            dateTimeSelector.dateTimeShifted(oldDateTime, deltaDateTime, newDateTime)
        }
    }
}
