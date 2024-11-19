// Version 6

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.kirigami 2.20 as Kirigami

Rectangle {
    id: messageWidget

    Layout.fillWidth: true

    property alias text: label.text
    property alias wrapMode: label.wrapMode
    property alias closeButtonVisible: closeButton.visible
    property alias animate: visibleAnimation.enabled
    property int iconSize: Kirigami.Units.iconSizes.large

    enum MessageType {
        Positive,
        Information,
        Warning,
        Error
    }
    property int messageType: MessageWidget.MessageType.Warning

    clip: true
    radius: Kirigami.Units.smallSpacing
    border.width: 1

    property var icon: {
        if (messageType == MessageWidget.MessageType.Information) {
            return "dialog-information"
        } else if (messageType == MessageWidget.MessageType.Warning) {
            return "dialog-warning"
        } else if (messageType == MessageWidget.MessageType.Error) {
            return "dialog-error"
        } else { // positive
            return "dialog-ok"
        }
    }

    property color gradBaseColor: {
        if (messageType == MessageWidget.MessageType.Information) {
            return Kirigami.Theme.positiveBackgroundColor
        } else if (messageType == MessageWidget.MessageType.Warning) {
            return Kirigami.Theme.neutralBackgroundColor
        } else if (messageType == MessageWidget.MessageType.Error) {
            return Kirigami.Theme.negativeBackgroundColor
        } else { // positive
            return Kirigami.Theme.positiveBackgroundColor
        }
    }

    border.color: {
        if (messageType == MessageWidget.MessageType.Information) {
            return Kirigami.Theme.positiveTextColor
        } else if (messageType == MessageWidget.MessageType.Warning) {
            return Kirigami.Theme.neutralTextColor
        } else if (messageType == MessageWidget.MessageType.Error) {
            return Kirigami.Theme.negativeTextColor
        } else { // positive
            return Kirigami.Theme.positiveTextColor
        }
    }

    property color labelColor: {
        if (messageType == MessageWidget.MessageType.Information) {
            return Kirigami.Theme.positiveTextColor
        } else if (messageType == MessageWidget.MessageType.Warning) {
            return Kirigami.Theme.neutralTextColor
        } else if (messageType == MessageWidget.MessageType.Error) {
            return Kirigami.Theme.negativeTextColor
        } else { // positive
            return Kirigami.Theme.positiveTextColor
        }
    }

    function show(message, messageType) {
        if (typeof messageType !== "undefined") {
            messageWidget.messageType = messageType
        }
        text = message
        visible = true
    }

    function success(message) {
        show(message, MessageWidget.MessageType.Positive)
    }

    function info(message) {
        show(message, MessageWidget.MessageType.Information)
    }

    function warn(message) {
        show(message, MessageWidget.MessageType.Warning)
    }

    function err(message) {
        show(message, MessageWidget.MessageType.Error)
    }

    function close() {
        visible = false
    }

    gradient: Gradient {
        GradientStop { position: 0.0; color: Qt.lighter(messageWidget.gradBaseColor, 1.1) }
        GradientStop { position: 0.1; color: messageWidget.gradBaseColor }
        GradientStop { position: 1.0; color: Qt.darker(messageWidget.gradBaseColor, 1.1) }
    }

    readonly property int expandedHeight: layout.implicitHeight + (2 * layout.anchors.margins)
    
    visible: text
    opacity: visible ? 1.0 : 0
    implicitHeight: visible ? messageWidget.expandedHeight : 0

    Component.onCompleted: {
        // Remove bindings
        visible = visible
        opacity = opacity
        if (visible) {
            implicitHeight = Qt.binding(function(){ return messageWidget.expandedHeight })
        } else {
            implicitHeight = 0
        }
    }

    Behavior on visible {
        id: visibleAnimation

        ParallelAnimation {
            PropertyAnimation {
                target: messageWidget
                property: "opacity"
                to: messageWidget.visible ? 0 : 1.0
                easing.type: Easing.Linear
            }
            PropertyAnimation {
                target: messageWidget
                property: "implicitHeight"
                to: messageWidget.visible ? 0 : messageWidget.expandedHeight
                easing.type: Easing.Linear
            }
        }
    }

    RowLayout {
        id: layout
        anchors.fill: parent
        anchors.margins: Kirigami.Units.smallSpacing
        spacing: Kirigami.Units.smallSpacing

        Kirigami.Icon {
            id: iconItem
            Layout.alignment: Qt.AlignVCenter
            implicitHeight: messageWidget.iconSize
            implicitWidth: messageWidget.iconSize
            source: messageWidget.icon
        }

        PlasmaComponents.Label {
            id: label
            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: true
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.WordWrap
            color: messageWidget.labelColor
        }

        PlasmaComponents.ToolButton {
            id: closeButton
            Layout.alignment: Qt.AlignVCenter
            icon.name: "dialog-close"
            onClicked: messageWidget.close()
        }
    }
}
