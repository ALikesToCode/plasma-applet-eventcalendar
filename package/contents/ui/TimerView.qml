import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.20 as Kirigami
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents

import "LocaleFuncs.js" as LocaleFuncs

Item {
    id: timerView

    property bool isSetTimerViewVisible: false

    implicitHeight: timerButtonView.height

    ColumnLayout {
        id: timerButtonView
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: Kirigami.Units.smallSpacing
        opacity: timerView.isSetTimerViewVisible ? 0 : 1
        visible: opacity > 0
        Behavior on opacity {
            NumberAnimation { duration: Kirigami.Units.shortDuration }
        }

        onWidthChanged: {
            bottomRow.updatePresetVisibilities()
        }

        RowLayout {
            id: topRow
            spacing: Kirigami.Units.largeSpacing
            property int contentsWidth: timerLabel.width + topRow.spacing + toggleButtonColumn.Layout.preferredWidth
            property bool contentsFit: timerButtonView.width >= contentsWidth

            PlasmaComponents.Button {
                id: timerLabel
                text: "0:00"
                icon.name: {
                    if (timerModel.secondsLeft === 0) {
                        return 'chronometer'
                    } else if (timerModel.running) {
                        return 'chronometer-pause'
                    } else {
                        return 'chronometer-start'
                    }
                }
                icon.width: Kirigami.Units.iconSizes.large
                icon.height: Kirigami.Units.iconSizes.large
                font.pointSize: -1
                font.pixelSize: appletConfig.timerClockFontHeight
                Layout.alignment: Qt.AlignVCenter
                property string tooltip: {
                    var s = ""
                    if (timerModel.secondsLeft > 0) {
                        if (timerModel.running) {
                            s += i18n("Pause Timer")
                        } else {
                            s += i18n("Start Timer")
                        }
                        s += "\n"
                    }
                    s += i18n("Scroll to add to duration")
                    return s
                }
                QQC2.ToolTip {
                    delay: Kirigami.Units.toolTipDelay
                    text: parent.tooltip
                    visible: parent.hovered
                }

                onClicked: {
                    if (timerModel.running) {
                        timerModel.pause()
                    } else if (timerModel.secondsLeft > 0) {
                        timerModel.runTimer()
                    }
                }

                MouseArea {
                    acceptedButtons: Qt.RightButton
                    anchors.fill: parent
                    onClicked: contextMenu.showBelow(timerLabel)
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.MiddleButton
                    onWheel: {
                        var delta = wheel.angleDelta.y || wheel.angleDelta.x
                        if (delta > 0) {
                            timerModel.increaseDuration()
                            timerModel.pause()
                        } else if (delta < 0) {
                            timerModel.decreaseDuration()
                            timerModel.pause()
                        }
                    }
                }
            }

            ColumnLayout {
                id: toggleButtonColumn
                Layout.alignment: Qt.AlignBottom
                Layout.minimumWidth: sizingButton.height
                Layout.preferredWidth: sizingButton.implicitWidth

                PlasmaComponents.Button {
                    id: sizingButton
                    text: "Test"
                    visible: false
                }

                PlasmaComponents.Button {
                    id: timerRepeatsButton
                    readonly property bool isChecked: Plasmoid.configuration.timerRepeats
                    icon.name: isChecked ? 'media-playlist-repeat' : 'gtk-stop'
                    text: topRow.contentsFit ? i18n("Repeat") : ""
                    onClicked: {
                        Plasmoid.configuration.timerRepeats = !isChecked
                    }
                    QQC2.ToolTip {
                        enabled: !topRow.contentsFit
                        text: i18n("Repeat")
                    }
                }

                PlasmaComponents.Button {
                    id: timerSfxEnabledButton
                    readonly property bool isChecked: Plasmoid.configuration.timerSfxEnabled
                    icon.name: isChecked ? 'audio-volume-high' : 'dialog-cancel'
                    text: topRow.contentsFit ? i18n("Sound") : ""
                    onClicked: {
                        Plasmoid.configuration.timerSfxEnabled = !isChecked
                    }
                    QQC2.ToolTip {
                        enabled: !topRow.contentsFit
                        text: i18n("Sound")
                    }
                }
            }
        }

        RowLayout {
            id: bottomRow
            spacing: Kirigami.Units.smallSpacing

            Repeater {
                id: defaultTimerRepeater
                model: timerModel.defaultTimers

                TimerPresetButton {
                    text: LocaleFuncs.durationShortFormat(modelData.seconds)
                    onClicked: timerModel.setDurationAndStart(modelData.seconds)
                }
            }

            function updatePresetVisibilities() {
                var availableWidth = timerButtonView.width
                var w = 0
                for (var i = 0; i < defaultTimerRepeater.count; i++) {
                    var item = defaultTimerRepeater.itemAt(i)
                    var itemWidth = item.width
                    if (i > 0) {
                        itemWidth += bottomRow.spacing
                    }
                    if (w + itemWidth <= availableWidth) {
                        item.visible = true
                    } else {
                        item.visible = false
                    }
                    w += itemWidth
                }
            }
        }
    }

    Loader {
        id: setTimerViewLoader
        anchors.fill: parent
        source: "TimerInputView.qml"
        active: timerView.isSetTimerViewVisible
        opacity: timerView.isSetTimerViewVisible ? 1 : 0
        visible: opacity > 0
        Behavior on opacity {
            NumberAnimation { duration: Kirigami.Units.shortDuration }
        }
    }

    Component.onCompleted: {
        timerView.forceActiveFocus()
    }

    Connections {
        target: timerModel
        function onSecondsLeftChanged() {
            timerLabel.text = timerModel.formatTimer(timerModel.secondsLeft)
        }
    }

    PlasmaComponents.Menu {
        id: contextMenu

        function newSeparator() {
            return Qt.createQmlObject("import org.kde.plasma.components 3.0 as PlasmaComponents; PlasmaComponents.MenuSeparator {}", contextMenu)
        }
        
        function newMenuItem() {
            return Qt.createQmlObject("import org.kde.plasma.components 3.0 as PlasmaComponents; PlasmaComponents.MenuItem {}", contextMenu)
        }

        function loadDynamicActions() {
            contextMenu.clearMenuItems()

            // Repeat
            var menuItem = newMenuItem()
            menuItem.icon.name = Plasmoid.configuration.timerRepeats ? 'media-playlist-repeat' : 'gtk-stop'
            menuItem.text = i18n("Repeat")
            menuItem.clicked.connect(function() {
                timerRepeatsButton.clicked()
            })
            contextMenu.addItem(menuItem)

            // Sound
            menuItem = newMenuItem()
            menuItem.icon.name = Plasmoid.configuration.timerSfxEnabled ? 'audio-volume-high' : 'gtk-stop'
            menuItem.text = i18n("Sound")
            menuItem.clicked.connect(function() {
                timerSfxEnabledButton.clicked()
            })
            contextMenu.addItem(menuItem)

            contextMenu.addItem(newSeparator())

            // Set Timer
            menuItem = newMenuItem()
            menuItem.icon.name = 'text-field'
            menuItem.text = i18n("Set Timer")
            menuItem.clicked.connect(function() {
                timerView.isSetTimerViewVisible = true
            })
            contextMenu.addItem(menuItem)

            contextMenu.addItem(newSeparator())

            for (var i = 0; i < timerModel.defaultTimers.length; i++) {
                var presetItem = timerModel.defaultTimers[i]
                menuItem = newMenuItem()
                menuItem.icon.name = 'chronometer'
                menuItem.text = LocaleFuncs.durationShortFormat(presetItem.seconds)
                menuItem.clicked.connect(timerModel.setDurationAndStart.bind(timerModel, presetItem.seconds))
                contextMenu.addItem(menuItem)
            }
        }

        function show(x, y) {
            loadDynamicActions()
            popup(x, y)
        }

        function showBelow(item) {
            loadDynamicActions()
            popup(item, PlasmaCore.Types.BottomPosedLeftAlignedPopup)
        }
    }
}
