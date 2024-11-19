import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.kirigami 2.20 as Kirigami

PlasmaComponents3.TextField {
	id: timerTextField
	Layout.fillWidth: true
	Layout.fillHeight: true
	font.pointSize: -1
	font.pixelSize: textFieldRow.fontPixelSize
	horizontalAlignment: TextInput.AlignHCenter
	property string defaultText: "00"
	text: defaultText
	
	// Use modern validator
	validator: IntValidator {
		bottom: 0
		top: 59
		locale: Qt.locale()
	}
	
	// Add tooltip for better UX
	Kirigami.MnemonicData.controlType: Kirigami.MnemonicData.FormElement
	Kirigami.FormData.label: i18n("Timer Value")
	
	// Handle focus changes
	onFocusChanged: {
		if (focus) {
			selectAll()
		} else {
			if (text === "") {
				text = defaultText
			}
		}
	}
	
	// Handle key events
	onAccepted: timerInputView.start()
	Keys.onEscapePressed: timerInputView.cancel()
	
	// Add theme support
	Kirigami.Theme.colorSet: Kirigami.Theme.View
	color: Kirigami.Theme.textColor
	
	// Add input validation feedback
	onTextChanged: {
		if (!acceptableInput) {
			PlasmaComponents3.ToolTip.show(i18n("Please enter a number between 0 and 59"))
		} else {
			PlasmaComponents3.ToolTip.hide()
		}
	}
}
