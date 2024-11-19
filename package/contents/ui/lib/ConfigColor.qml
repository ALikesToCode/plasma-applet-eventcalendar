// Version 6

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import QtQuick.Window
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

import ".."

RowLayout {
    id: configColor
    spacing: 2
    Layout.maximumWidth: 300 * Kirigami.Units.devicePixelRatio

    property alias label: label.text
    property alias labelColor: label.color 
    property alias horizontalAlignment: label.horizontalAlignment
    property alias showAlphaChannel: dialog.showAlphaChannel
    property color buttonOutlineColor: {
        if (valueColor.r + valueColor.g + valueColor.b > 0.5) {
            return "#BB000000" // Black outline
        } else {
            return "#BBFFFFFF" // White outline
        }
    }

    property TextField textField: textField
    property ColorDialog dialog: dialog

    property string configKey: ''
    property string defaultColor: ''
    property string value: {
        if (configKey) {
            return plasmoid.configuration[configKey]
        } else {
            return "#000"
        }
    }

    readonly property color defaultColorValue: defaultColor
    readonly property color valueColor: {
        if (value == '' && defaultColor) {
            return defaultColor
        } else {
            return value
        }
    }

    onValueChanged: {
        if (!textField.activeFocus) {
            textField.text = configColor.value
        }
        if (configKey) {
            if (value == defaultColorValue) {
                plasmoid.configuration[configKey] = ""
            } else {
                plasmoid.configuration[configKey] = value
            }
        }
    }

    function setValue(newColor) {
        textField.text = newColor
    }

    PlasmaComponents.Label {
        id: label
        text: "Label"
        Layout.fillWidth: horizontalAlignment == Text.AlignRight
        horizontalAlignment: Text.AlignLeft
        color: Kirigami.Theme.textColor
    }

    MouseArea {
        id: mouseArea
        Layout.preferredWidth: textField.height
        Layout.preferredHeight: textField.height
        hoverEnabled: true

        onClicked: dialog.open()

        Rectangle {
            anchors.fill: parent
            color: configColor.valueColor
            border.width: 2
            border.color: parent.containsMouse ? Kirigami.Theme.highlightColor : buttonOutlineColor
            Kirigami.Theme.colorSet: Kirigami.Theme.View
        }
    }

    PlasmaComponents.TextField {
        id: textField
        placeholderText: defaultColor ? defaultColor : "#AARRGGBB"
        Layout.fillWidth: label.horizontalAlignment == Text.AlignLeft
        color: Kirigami.Theme.textColor
        background: Rectangle {
            color: Kirigami.Theme.backgroundColor
            border.color: Kirigami.Theme.highlightColor
            border.width: parent.activeFocus ? 2 : 1
            radius: 4
        }
        
        onTextChanged: {
            // Make sure the text is:
            //   Empty (use default)
            //   or #123 or #112233 or #11223344 before applying the color.
            if (text.length === 0
                || (text.indexOf('#') === 0 && (text.length == 4 || text.length == 7 || text.length == 9))
            ) {
                configColor.value = text
            }
        }
    }

    ColorDialog {
        id: dialog
        visible: false
        modality: Qt.WindowModal
        title: configColor.label
        showAlphaChannel: true
        color: configColor.valueColor
        onAccepted: {
            configColor.value = selectedColor
        }
        onCurrentColorChanged: {
            if (visible && color != currentColor) {
                configColor.value = currentColor
            }
        }
    }
}
