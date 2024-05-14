/*
 * Copyright 2013  Heena Mahour <heena393@gmail.com>
 * Copyright 2013 Sebastian Kügler <sebas@kde.org>
 * Copyright 2015, 2016 Kai Uwe Broulik <kde@privat.broulik.de>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of
 * the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15 as QQC2

import org.kde.kirigami 2.15 as Kirigami
import org.kde.plasma.calendar
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.plasma.extras 2.0 as PlasmaExtras

import "./badges"

Item {
    id: daysCalendar

    signal headerClicked

    signal previous
    signal next

    signal activated(int index, var date, var item)
    signal doubleClicked(int index, var date, var item)
    signal activateHighlightedItem

    readonly property int gridColumns: showWeekNumbers ? calendarGrid.columns + 1 : calendarGrid.columns

    property alias previousLabel: previousButton.tooltip
    property alias nextLabel: nextButton.tooltip

    property int rows
    property int columns

    property bool showWeekNumbers
    property string eventBadgeType: "theme"
    property string todayStyle: "theme"

    onShowWeekNumbersChanged: canvas.requestPaint()

    property int dateMatchingPrecision

    property alias headerModel: days.model
    property alias gridModel: repeater.model

    property alias title: heading.text

    readonly property int cellWidth: Math.floor((stack.width - (daysCalendar.columns + 1) * root.borderWidth) / (daysCalendar.columns + (showWeekNumbers ? 1 : 0)))
    readonly property int cellHeight:  Math.floor((stack.height - heading.height - calendarGrid.rows * root.borderWidth) / calendarGrid.rows)

    property real transformScale: 1
    property point transformOrigin: Qt.point(width / 2, height / 2)

    transform: Scale {
        xScale: daysCalendar.transformScale
        yScale: xScale
        origin.x: transformOrigin.x
        origin.y: transformOrigin.y
    }

    Behavior on transformScale {
        id: scaleBehavior
        NumberAnimation {
            duration: Kirigami.Units.longDuration
        }
    }

    QQC2.StackView.onStatusChanged: {
        if (QQC2.StackView.status === QQC2.StackView.Inactive) {
            daysCalendar.transformScale = 1
            daysCalendar.opacity = 1
        }
    }

    RowLayout {
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        spacing: Kirigami.Units.smallSpacing

        PlasmaExtras.Heading {
            id: heading

            Layout.fillWidth: true

            level: root.headingFontLevel
            wrapMode: Text.NoWrap
            elide: Text.ElideRight
            font.capitalization: Font.Capitalize
            Layout.preferredHeight: implicitHeight + implicitHeight % 2

            MouseArea {
                id: monthMouse
                property int previousPixelDelta

                anchors.fill: parent
                onClicked: {
                    if (!stack.busy) {
                        daysCalendar.headerClicked()
                    }
                }
                onExited: previousPixelDelta = 0
                onWheel: {
                    var delta = wheel.angleDelta.y || wheel.angleDelta.x
                    var pixelDelta = wheel.pixelDelta.y || wheel.pixelDelta.x

                    if (pixelDelta) {
                        if (Math.abs(previousPixelDelta) < monthMouse.height) {
                            previousPixelDelta += pixelDelta
                            return
                        }
                    }

                    if (delta >= 15) {
                        daysCalendar.previous()
                    } else if (delta <= -15) {
                        daysCalendar.next()
                    }
                    previousPixelDelta = 0
                }
            }
        }

        PlasmaComponents3.ToolButton {
            id: previousButton
            icon.name: "go-previous"
            onClicked: daysCalendar.previous()
            property string tooltip: ''
            QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
            QQC2.ToolTip.text: tooltip
            QQC2.ToolTip.visible: hovered
            Accessible.name: tooltip
            Layout.preferredHeight: implicitHeight + implicitHeight % 2
        }

        PlasmaComponents3.ToolButton {
            icon.name: "go-jump-today"
            onClicked: root.resetToToday()
            property string tooltip: i18ndc("libplasma5", "Reset calendar to today", "Today")
            QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
            QQC2.ToolTip.text: tooltip
            QQC2.ToolTip.visible: hovered
            Accessible.name: tooltip
            Accessible.description: i18nd("libplasma5", "Reset calendar to today")
            Layout.preferredHeight: implicitHeight + implicitHeight % 2
        }

        PlasmaComponents3.ToolButton {
            id: nextButton
            icon.name: "go-next"
            onClicked: daysCalendar.next()
            property string tooltip: ''
            QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
            QQC2.ToolTip.text: tooltip
            QQC2.ToolTip.visible: hovered
            Accessible.name: tooltip
            Layout.preferredHeight: implicitHeight + implicitHeight % 2
        }
    }

    Canvas {
        id: canvas

        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
        }
        width: (daysCalendar.cellWidth + root.borderWidth) * gridColumns + root.borderWidth
        height: (daysCalendar.cellHeight + root.borderWidth) * calendarGrid.rows + root.borderWidth

        opacity: root.borderOpacity
        antialiasing: false
        clip: false
        onPaint: {
            var ctx = getContext("2d");
            ctx.reset()
            ctx.save()
            ctx.clearRect(0, 0, canvas.width, canvas.height)
            ctx.strokeStyle = PlasmaCore.ColorScope.textColor
            ctx.lineWidth = root.borderWidth
            ctx.globalAlpha = 1.0

            ctx.beginPath()

            var lineBasePoint = Math.floor(root.borderWidth / 2)

            for (var i = 0; i < calendarGrid.rows + 1; i++) {
                var lineY = lineBasePoint + (daysCalendar.cellHeight + root.borderWidth) * (i)

                if (i === 0 || i === calendarGrid.rows) {
                    ctx.moveTo(0, lineY)
                } else {
                    ctx.moveTo(showWeekNumbers ? daysCalendar.cellWidth + root.borderWidth : root.borderWidth, lineY)
                }
                ctx.lineTo(width, lineY)
            }

            for (var i = 0; i < gridColumns + 1; i++) {
                var lineX = lineBasePoint + (daysCalendar.cellWidth + root.borderWidth) * (i)

                if (i == 0 || i == gridColumns || !daysCalendar.headerModel) {
                    ctx.moveTo(lineX, 0)
                } else {
                    ctx.moveTo(lineX, root.borderWidth + daysCalendar.cellHeight)
                }
                ctx.lineTo(lineX, height)
            }

            ctx.closePath()
            ctx.stroke()
            ctx.restore()
        }
    }

    PlasmaCore.Svg {
        id: calendarSvg
        imagePath: "widgets/calendar"
    }

    Component {
        id: themeBadgeComponent
        Item {
            id: themeBadge
            PlasmaCore.SvgItem {
                id: eventsMarker
                anchors.bottom: themeBadge.bottom
                anchors.right: themeBadge.right
                height: parent.height / 3
                width: height
                svg: calendarSvg
                elementId: "event"
            }
        }
    }

    Component {
        id: highlightBarBadgeComponent
        HighlightBarBadge {}
    }

    Component {
        id: eventColorsBarBadgeComponent
        EventColorsBarBadge {}
    }

    Component {
        id: dotsBadgeComponent
        DotsBadge {}
    }

    Component {
        id: eventCountBadgeComponent
        EventCountBadge {}
    }

    Connections {
        target: theme
        function onTextColorChanged() {
            canvas.requestPaint()
        }
    }

    Column {
        id: weeksColumn
        visible: showWeekNumbers
        anchors {
            top: canvas.top
            left: canvas.left
            bottom: canvas.bottom
            topMargin: daysCalendar.cellHeight + root.borderWidth + root.borderWidth
        }
        spacing: root.borderWidth

        Repeater {
            model: showWeekNumbers ? calendarBackend.weeksModel : []

            PlasmaComponents3.Label {
                height: daysCalendar.cellHeight
                width: daysCalendar.cellWidth
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.pointSize: -1 // Ignore pixelSize warning
                font.pixelSize: Math.max(theme.smallestFont.pixelSize, Math.min(daysCalendar.cellHeight / 3, daysCalendar.cellWidth * 5 / 8))
                readonly property bool isCurrentWeek: root.currentMonthContainsToday && modelData == calendarBackend.currentWeek()
                readonly property bool showHighlight: isCurrentWeek && root.highlightCurrentDayWeek
                color: showHighlight ? PlasmaCore.ColorScope.highlightColor : PlasmaCore.ColorScope.textColor
                opacity: showHighlight ? 0.75 : 0.4
                text: modelData
            }
        }
    }

    Grid {
        id: calendarGrid

        anchors {
            right: canvas.right
            rightMargin: root.borderWidth
            bottom: parent.bottom
            bottomMargin: root.borderWidth
        }

        columns: daysCalendar.columns
        rows: daysCalendar.rows + (daysCalendar.headerModel ? 1 : 0)

        spacing: root.borderWidth
        property Item selectedItem
        property bool containsEventItems: false // FIXME
        property bool containsTodoItems: false // FIXME

        property QtObject selectedDate: root.date
        onSelectedDateChanged: {
            if (calendarGrid.selectedDate == null) {
                calendarGrid.selectedItem = null
            }
        }

        Repeater {
            id: days

            PlasmaComponents3.Label {
                width: daysCalendar.cellWidth
                height: daysCalendar.cellHeight
                font.pointSize: -1 // Ignore pixelSize warning
                font.pixelSize: Math.max(theme.smallestFont.pixelSize, Math.min(daysCalendar.cellHeight / 3, daysCalendar.cellWidth * 5 / 8))
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
                fontSizeMode: Text.HorizontalFit
                readonly property int currentDayIndex: (calendarBackend.firstDayOfWeek + index) % 7
                readonly property bool isCurrentDay: root.currentMonthContainsToday && root.today && root.today.getDay() === currentDayIndex
                readonly property bool showHighlight: isCurrentDay && root.highlightCurrentDayWeek
                color: showHighlight ? PlasmaCore.ColorScope.highlightColor : PlasmaCore.ColorScope.textColor
                opacity: showHighlight ? 0.75 : 0.4
                text: Qt.locale().dayName(currentDayIndex, Locale.ShortFormat)
            }
        }

        Repeater {
            id: repeater

            DayDelegate {
                id: delegate
                width: daysCalendar.cellWidth
                height: daysCalendar.cellHeight

                onClicked: daysCalendar.activated(index, model, delegate)
                onDoubleClicked: daysCalendar.doubleClicked(index, model, delegate)

                eventBadgeType: {
                    switch (daysCalendar.eventBadgeType) {
                        case 'bottomBar':
                        case 'dots':
                            return daysCalendar.eventBadgeType

                        case 'theme':
                        default:
                            if (calendarSvg.hasElement('event')) {
                                return daysCalendar.eventBadgeType
                            } else {
                                return 'bottomBar'
                            }
                    }
                }

                todayStyle: {
                    switch (daysCalendar.todayStyle) {
                        case 'bigNumber':
                            return daysCalendar.todayStyle

                        case 'theme':
                        default:
                            return 'theme'
                    }
                }

                Connections {
                    target: daysCalendar
                    function onActivateHighlightedItem() {
                        if (delegate.containsMouse) {
                            delegate.clicked(null)
                        }
                    }
                }
            }
        }
    }
}
