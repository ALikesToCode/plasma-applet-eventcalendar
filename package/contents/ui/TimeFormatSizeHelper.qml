import QtQuick 2.15
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.kirigami 2.20 as Kirigami

Item {
    id: timeFormatSizeHelper
    visible: false

    property Text timeLabel

    FontMetrics {
        id: fontMetrics

        font.pointSize: -1
        font.pixelSize: timeLabel.font.pixelSize
        font.family: timeLabel.font.family
        font.weight: timeLabel.font.weight
        font.italic: timeLabel.font.italic
    }

    function getWidestNumber(fontMetrics) {
        // Find widest character between 0 and 9
        var maximumWidthNumber = 0
        var maximumAdvanceWidth = 0
        for (var i = 0; i <= 9; i++) {
            var advanceWidth = fontMetrics.advanceWidth(i)
            if (advanceWidth > maximumAdvanceWidth) {
                maximumAdvanceWidth = advanceWidth
                maximumWidthNumber = i
            }
        }
        return maximumWidthNumber
    }

    readonly property string widestTimeFormat: {
        try {
            var maximumWidthNumber = getWidestNumber(fontMetrics)
            // Replace all placeholders with the widest number (two digits)
            return timeLabel.timeFormat.replace(/(h+|m+|s+)/g, maximumWidthNumber.toString() + maximumWidthNumber.toString())
        } catch (e) {
            console.warn("Error calculating widest time format:", e)
            return "00:00" // Fallback format
        }
    }

    readonly property real minWidth: formattedSizeHelper.paintedWidth

    function updateMinWidth() {
        try {
            var now = new Date(timeModel.currentTime)
            var date = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 1, 0, 0)
            var timeAm = Qt.formatDateTime(date, widestTimeFormat)
            var advanceWidthAm = fontMetrics.advanceWidth(timeAm)
            
            date.setHours(13)
            var timePm = Qt.formatDateTime(date, widestTimeFormat)
            var advanceWidthPm = fontMetrics.advanceWidth(timePm)

            formattedSizeHelper.text = advanceWidthAm > advanceWidthPm ? timeAm : timePm
        } catch (e) {
            console.warn("Error updating min width:", e)
            formattedSizeHelper.text = "00:00" // Fallback text
        }
    }

    PlasmaComponents3.Label {
        id: formattedSizeHelper

        font.pointSize: -1
        font.pixelSize: timeLabel.font.pixelSize
        font.family: timeLabel.font.family
        font.weight: timeLabel.font.weight
        font.italic: timeLabel.font.italic
        wrapMode: timeLabel.wrapMode
        fontSizeMode: Text.FixedSize
    }

    Connections {
        target: clock
        function onWidthChanged() {
            Qt.callLater(timeFormatSizeHelper.updateMinWidth)
        }
        function onHeightChanged() {
            Qt.callLater(timeFormatSizeHelper.updateMinWidth)
        }
    }

    Connections {
        target: timeLabel
        function onHeightChanged() {
            Qt.callLater(timeFormatSizeHelper.updateMinWidth)
        }
        function onTimeFormatChanged() {
            Qt.callLater(timeFormatSizeHelper.updateMinWidth)
        }
    }

    Connections {
        target: timeModel
        function onDateChanged() {
            Qt.callLater(timeFormatSizeHelper.updateMinWidth)
        }
    }

    Component.onCompleted: {
        updateMinWidth()
    }
}
