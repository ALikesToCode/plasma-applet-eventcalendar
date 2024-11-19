import QtQuick 2.15
import org.kde.plasma.plasmoid 2.0
import org.kde.kirigami 2.20 as Kirigami
import org.kde.plasma.core as PlasmaCore

QtObject {
    id: timerModel

    property int secondsLeft: 0
    property int duration: 0
    readonly property bool timerRepeats: plasmoid.configuration.timerRepeats
    readonly property bool timerSfxEnabled: plasmoid.configuration.timerSfxEnabled
    readonly property string timerSfxFilepath: plasmoid.configuration.timerSfxFilepath
    property alias running: timerTicker.running
    property date finished: new Date()

    signal timerFinished()

    property var defaultTimers: [
        { seconds: 30 },
        { seconds: 60 },
        { seconds: 5 * 60 },
        { seconds: 10 * 60 },
        { seconds: 15 * 60 },
        { seconds: 20 * 60 },
        { seconds: 30 * 60 },
        { seconds: 45 * 60 },
        { seconds: 60 * 60 },
    ]

    property Timer timerTicker: Timer {
        id: timerTicker
        interval: 1000
        running: false
        repeat: true
        triggeredOnStart: true

        onTriggered: {
            timerModel.tick()
        }
    }

    function setDuration(newDuration) {
        if (newDuration <= 0) {
            return
        }
        timerModel.duration = newDuration
        timerModel.secondsLeft = newDuration
    }

    function setDurationAndStart(newDuration) {
        setDuration(newDuration)
        if (newDuration > 0) {
            timerModel.runTimer()
        }
    }

    function getIncrementFor(oldDuration, multiplier) {
        if (oldDuration >= 15 * 60) { // 15m
            return 5 * 60 // +5m
        } else if (oldDuration >= 60) { // 1m
            if (multiplier < 0 && oldDuration < 120) { // 1-2m -5sec
                return 5 // -5sec
            } else {
                return 60 // +1m
            }
        } else if (oldDuration >= 15) { // 15sec
            return 5 // +5sec
        } else {
            if (multiplier < 0 && oldDuration <= 1) { // 0-1sec
                return 0 // +0
            } else { // 2-14sec
                return 1 // +1sec
            }
        }
    }

    function deltaDuration(multiplier) {
        var delta = getIncrementFor(duration, multiplier)
        var newDuration = Math.max(0, timerModel.duration + (delta * multiplier))
        setDuration(newDuration)
    }

    function increaseDuration() {
        deltaDuration(1)
    }

    function decreaseDuration() {
        deltaDuration(-1)
    }

    onDurationChanged: {
        secondsLeft = duration
    }

    onSecondsLeftChanged: {
        if (secondsLeft <= 0) {
            timerFinished()
        }
    }

    function formatTimer(nSeconds) {
        var hours = Math.floor(nSeconds / 3600)
        var minutes = Math.floor((nSeconds - hours*3600) / 60)
        var seconds = nSeconds - hours*3600 - minutes*60
        var s = "" + (seconds < 10 ? "0" : "") + seconds
        s = minutes + ":" + s
        if (hours > 0) {
            s = hours + ":" + (minutes < 10 ? "0" : "") + s
        }
        return s
    }

    function tick() {
        var now = new Date()
        var deltaMillis = finished.valueOf() - now.valueOf()
        timerModel.secondsLeft = Math.max(0, Math.ceil(deltaMillis / 1000))
    }

    function repeatTimer() {
        timerModel.secondsLeft = timerModel.duration
        timerModel.runTimer()
    }

    function runTimer() {
        var now = new Date()
        timerModel.finished = new Date(now.valueOf() + timerModel.secondsLeft * 1000)
        timerTicker.restart()
    }

    function pause() {
        timerTicker.stop()
    }

    onTimerFinished: {
        timerModel.pause()
        timerModel.createNotification()

        if (timerModel.timerRepeats) {
            timerModel.repeatTimer()
        }
    }

    function createNotification() {
        var args = {
            appName: i18n("Timer"),
            appIcon: "chronometer",
            summary: i18n("Timer finished"),
            body: i18n("%1 has passed", formatTimer(timerModel.duration)),
            urgency: Kirigami.MessageType.Warning
        }

        if (timerModel.timerSfxEnabled) {
            args.soundFile = timerModel.timerSfxFilepath
        }

        args.actions = []
        if (!timerModel.timerRepeats) {
            args.actions.push({
                id: 'repeat',
                text: i18n("Repeat")
            })
        }

        notificationManager.notify(args, function(actionId) {
            if (actionId === 'repeat') {
                repeatTimer()
            }
        })
    }
}
