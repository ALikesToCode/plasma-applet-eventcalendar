/*
 * Copyright 2013 Heena Mahour <heena393@gmail.com>
 * Copyright 2013 Sebastian Kügler <sebas@kde.org>
 * Copyright 2015 Kai Uwe Broulik <kde@privat.broulik.de>
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
import org.kde.kirigami 2.20 as Kirigami
import org.kde.plasma.components 3.0 as PlasmaComponents3

Item {
    id: dayStyle

    property int borderWidth: plasmoid.configuration.monthShowBorder ? 1 : 0
    property real borderOpacity: 0.4
    property color borderColor: Kirigami.Theme.textColor

    property bool showEventBadge: true
    property bool useHighlightColor: false
    property var eventColors: []

    property string eventBadgeType: plasmoid.configuration.monthEventBadgeType
    property string todayStyle: plasmoid.configuration.monthTodayStyle

    property bool selected: false
    property bool today: false
    property bool thisMonth: true
    property bool firstDayOfMonth: false

    property alias dayLabel: dayLabel
    property alias mouseArea: mouseArea

    Rectangle {
        id: background
        anchors.fill: parent
        color: {
            if (selected) {
                return Kirigami.Theme.highlightColor
            } else if (today && todayStyle == 'theme') {
                return Kirigami.Theme.highlightColor
            } else {
                return "transparent"
            }
        }
        opacity: {
            if (selected) {
                return 0.6
            } else if (today && todayStyle == 'theme') {
                return 0.6
            } else {
                return 1
            }
        }
        radius: plasmoid.configuration.monthCellRadius * Math.min(width, height)
    }

    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.width: borderWidth
        border.color: borderColor
        opacity: borderOpacity
        radius: background.radius
    }

    PlasmaComponents3.Label {
        id: dayLabel
        anchors.centerIn: parent
        width: Math.min(parent.width, parent.height)
        height: width
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        opacity: thisMonth ? 1 : 0.5
        font.weight: {
            if (today && todayStyle == 'bigNumber') {
                return Font.Bold
            } else {
                return Font.Normal
            }
        }
        font.pixelSize: {
            if (today && todayStyle == 'bigNumber') {
                return Math.max(6 * Kirigami.Units.devicePixelRatio, width * 2/3)
            } else {
                return Math.max(6 * Kirigami.Units.devicePixelRatio, width/3)
            }
        }
        color: {
            if (selected) {
                return Kirigami.Theme.highlightedTextColor
            } else if (today && todayStyle == 'theme') {
                return Kirigami.Theme.highlightedTextColor
            } else {
                return Kirigami.Theme.textColor
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
    }

    states: [
        State {
            name: "hover"
            when: mouseArea.containsMouse
            PropertyChanges {
                target: background
                opacity: selected ? 0.4 : 0.2
            }
        }
    ]
}
