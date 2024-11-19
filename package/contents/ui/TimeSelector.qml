import QtQuick
import QtQuick.Window
import org.kde.plasma.components 3.0 as PlasmaComponents3
import QtQuick.Templates as T
import QtQuick.Controls as Controls
import QtQuick.Effects
import org.kde.kirigami as Kirigami

PlasmaComponents3.TextField {
    id: timeSelector
    readonly property Item control: timeSelector

    property int defaultMinimumWidth: Kirigami.Units.gridUnit * 10
    readonly property int implicitContentWidth: contentWidth + leftPadding + rightPadding
    implicitWidth: Math.max(defaultMinimumWidth, implicitContentWidth)

    property var dateTime: new Date()
    property var timeFormat: Locale.ShortFormat

    signal dateTimeShifted(date oldDateTime, int deltaDateTime, date newDateTime)
    signal entryActivated(int index)

    function setDateTime(newDateTime) {
        var oldDateTime = new Date(dateTime)
        var deltaDateTime = newDateTime.valueOf() - oldDateTime.valueOf()
        dateTimeShifted(oldDateTime, deltaDateTime, newDateTime)
    }

    function updateText() {
        text = Qt.binding(function(){
            return timeSelector.dateTime.toLocaleTimeString(Qt.locale(), timeSelector.timeFormat)
        })
    }

    property string valueRole: "dt"
    property string textRole: "label"
    property var model: {
        var dt = dateTime
        var midnight = new Date(dt.getFullYear(), dt.getMonth(), dt.getDate(), 0, 0, 0)
        var interval = 30 // minutes
        var intervalMillis = interval*60*1000
        var numEntries = Math.ceil(24*60 / interval)
        var l = []
        for (var i = 0; i < numEntries; i++) {
            var deltaT = i * intervalMillis
            var entryDateTime = new Date(midnight.valueOf() + deltaT)
            var entry = {
                dt: entryDateTime,
                label: entryDateTime.toLocaleTimeString(Qt.locale(), timeSelector.timeFormat)
            }
            l.push(entry)
        }
        return l
    }

    onPressed: {
        popup.open()
        highlightDateTime(dateTime)
    }

    onEntryActivated: {
        if (0 <= index && index < model.length) {
            var entry = model[index]
            setDateTime(entry[control.valueRole])
        }
    }

    onTextEdited: {
        var dt = Date.fromLocaleTimeString(Qt.locale(), text, timeSelector.timeFormat)
        if (!isNaN(dt)) {
            setDateTime(dt)
            highlightDateTime(dt)
        }
    }

    function highlightDateTime(dt) {
        for (var i = 0; i < model.length; i++) {
            var entry = model[i]
            var eDT = entry[valueRole]
            if (dt.getHours() === eDT.getHours() && dt.getMinutes() === eDT.getMinutes()) {
                listView.currentIndex = i
                listView.positionViewAtIndex(i, ListView.Contain)
                return
            }
        }
        listView.currentIndex = -1
    }

    onEditingFinished: updateText()
    Component.onCompleted: updateText()

    property Component delegate: PlasmaComponents3.ItemDelegate {
        width: control.popup.width
        text: control.textRole ? (Array.isArray(control.model) ? modelData[control.textRole] : model[control.textRole]) : modelData
        property bool separatorVisible: false
        highlighted: listView.currentIndex === index

        onClicked: {
            listView.currentIndex = index
            control.entryActivated(listView.currentIndex)
            popup.close()
        }
    }

    property T.Popup popup: T.Popup {
        x: control.mirrored ? control.width - width : 0
        y: control.height
        property int minWidth: Kirigami.Units.gridUnit * 15
        property int maxHeight: Kirigami.Units.gridUnit * 18
        width: Math.max(control.width, minWidth)
        implicitHeight: Math.min(contentItem.implicitHeight, maxHeight)
        topMargin: Kirigami.Units.smallSpacing
        bottomMargin: Kirigami.Units.smallSpacing

        contentItem: ListView {
            id: listView
            clip: true
            implicitHeight: contentHeight
            highlightRangeMode: ListView.ApplyRange
            highlightMoveDuration: 0
            LayoutMirroring.enabled: Qt.application.layoutDirection === Qt.RightToLeft
            LayoutMirroring.childrenInherit: true
            T.ScrollBar.vertical: Controls.ScrollBar { }

            model: control.popup.visible ? control.model : null
            delegate: control.delegate
        }

        background: Rectangle {
            anchors {
                fill: parent
                margins: -1
            }
            radius: Kirigami.Units.smallSpacing
            color: Kirigami.Theme.viewBackgroundColor
            border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.3)
            layer.enabled: true

            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Qt.rgba(0, 0, 0, 0.3)
                shadowBlur: 1.0
                shadowHorizontalOffset: 2
                shadowVerticalOffset: 2
            }
        }
    }
}
