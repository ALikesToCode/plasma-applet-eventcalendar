import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents3

PlasmaComponents3.TextField {
	id: timerTextField
	Layout.fillWidth: true
	Layout.fillHeight: true
	font.pointSize: -1
	font.pixelSize: textFieldRow.fontPixelSize
	horizontalAlignment: PlasmaComponents3.TextField.AlignHCenter
	property string defaultText: "00"
	text: defaultText
	validator: IntValidator { bottom: 0; top: 59 }
	onFocusChanged: {
		if (focus) {
			selectAll()
		} else {
			if (text === "") {
				text = defaultText
			}
		}
	}
	onAccepted: timerInputView.start()
	Keys.onEscapePressed: timerInputView.cancel()
}
