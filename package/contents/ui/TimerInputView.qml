import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.kirigami 2.20 as Kirigami

ColumnLayout {
    id: timerInputView
    spacing: Kirigami.Units.smallSpacing

    readonly property int totalSeconds: {
        var h = parseInt(hoursTextField.text || "0", 10)
        var m = parseInt(minutesTextField.text || "0", 10)
        var s = parseInt(secondsTextField.text || "0", 10)

        return (h*60*60) + (m*60) + (s)
    }

    function reset() {
        hoursTextField.text = "0"
        minutesTextField.text = "00"
        secondsTextField.text = "00"
    }

    function cancel() {
        timerInputView.reset()
        timerView.isSetTimerViewVisible = false
    }

    function start() {
        if (totalSeconds <= 0) {
            showPassiveNotification(i18n("Please enter a duration greater than zero"))
            return
        }
        timerModel.setDurationAndStart(timerInputView.totalSeconds)
        timerView.isSetTimerViewVisible = false
    }

    RowLayout {
        id: textFieldRow
        Layout.fillHeight: true
        Layout.alignment: Qt.AlignHCenter
        spacing: Kirigami.Units.smallSpacing

        property int fontPixelSize: height/2

        TimerTextField {
            id: hoursTextField
            defaultText: "0"
            validator: IntValidator { 
                bottom: 0
                top: 999
            }
            KeyNavigation.tab: minutesTextField
        }

        PlasmaComponents3.Label {
            Layout.fillHeight: true
            font.pointSize: -1
            font.pixelSize: textFieldRow.fontPixelSize
            text: ":"
        }

        TimerTextField {
            id: minutesTextField
            validator: IntValidator {
                bottom: 0
                top: 59
            }
            KeyNavigation.tab: secondsTextField
            KeyNavigation.backtab: hoursTextField
        }

        PlasmaComponents3.Label {
            Layout.fillHeight: true
            font.pointSize: -1
            font.pixelSize: textFieldRow.fontPixelSize
            text: ":"
        }

        TimerTextField {
            id: secondsTextField
            validator: IntValidator {
                bottom: 0
                top: 59
            }
            KeyNavigation.backtab: minutesTextField
        }
    }

    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: Kirigami.Units.smallSpacing

        PlasmaComponents3.Button {
            icon.name: 'chronometer-start'
            text: i18n("&Start")
            onClicked: timerInputView.start()
            KeyNavigation.tab: cancelButton
        }
        
        PlasmaComponents3.Button {
            id: cancelButton
            icon.name: 'dialog-cancel'
            text: i18n("&Cancel")
            onClicked: timerInputView.cancel()
            KeyNavigation.backtab: startButton
        }
    }

    Component.onCompleted: {
        minutesTextField.forceActiveFocus()
    }
}
