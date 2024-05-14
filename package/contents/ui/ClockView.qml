/*
 * Copyright 2013 Heena Mahour <heena393@gmail.com>
 * Copyright 2013 Sebastian Kügler <sebas@kde.org>
 * Copyright 2013 Martin Klapetek <mklapetek@kde.org>
 * Copyright 2014 David Edmundson <davidedmundson@kde.org>
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
import QtQuick.Layouts
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

Item {
    id: clock

    property int horizontalFixedLineWidth: 300 * Kirigami.Units.devicePixelRatio
    property int verticalFixedLineHeight: 24 * Kirigami.Units.devicePixelRatio

    property int targetHeight: verticalFixedLineHeight

    property int horizontalHeight: {
        if (useFixedHeight) {
            return fixedHeight
        } else {
            if (showLine2) {
                // DigitalClock default
                var timeHeight = clock.height * 0.56
                var dateHeight = timeHeight * 0.8
                return timeHeight + dateHeight
            } else {
                // DigitalClock default
                var timeHeight = clock.height * 0.71
                return timeHeight
            }
        }
    }

    property int verticalHeight: {
        if (useFixedHeight) {
            return fixedHeight
        } else {
            if (showLine2) {
                var timeHeight = verticalFixedLineHeight
                var dateHeight = timeHeight * 0.8
                return timeHeight + dateHeight
            } else {
                var timeHeight = verticalFixedLineHeight
                return timeHeight
            }
        }
    }

    property date currentTime: new Date()

    readonly property int fixedHeight: plasmoid.configuration.clockMaxHeight
    readonly property bool useFixedHeight: fixedHeight > 0

    readonly property bool showLine2: plasmoid.configuration.clockShowLine2
    readonly property int lineHeight2: targetHeight * plasmoid.configuration.clockLine2HeightRatio
    readonly property int lineHeight1: showLine2 ? targetHeight - lineHeight2 : targetHeight

    readonly property real fixedWidth: showLine2 ? Math.max(timeFormatSizer1.minWidth, timeFormatSizer2.minWidth) : timeFormatSizer1.minWidth

    Column {
        id: labels
        spacing: 0
        anchors.centerIn: parent

        Item {
            id: timeContainer1

            Kirigami.Label {
                id: timeLabel1
                anchors.centerIn: parent

                font.family: appletConfig.clockFontFamily
                font.weight: appletConfig.lineWeight1
                font.pointSize: -1
                font.pixelSize: timeContainer1.height
                minimumPixelSize: 1

                fontSizeMode: Text.FixedSize
                wrapMode: Text.NoWrap

                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                smooth: true

                property string timeFormat: appletConfig.line1TimeFormat
                text: Qt.formatDateTime(clock.currentTime, timeFormat)
            }
        }
        Item {
            id: timeContainer2
            visible: clock.showLine2

            Kirigami.Label {
                id: timeLabel2
                anchors.centerIn: parent
                font.family: appletConfig.clockFontFamily
                font.weight: appletConfig.lineWeight2
                font.pointSize: -1
                font.pixelSize: timeContainer2.height
                minimumPixelSize: 1

                fontSizeMode: Text.FixedSize
                wrapMode: Text.NoWrap

                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                smooth: true

                property string timeFormat: appletConfig.line2TimeFormat
                text: Qt.formatDateTime(clock.currentTime, timeFormat)
            }
        }
    }

    TimeFormatSizeHelper {
        id: timeFormatSizer1
        timeLabel: timeLabel1
    }
    TimeFormatSizeHelper {
        id: timeFormatSizer2
        timeLabel: timeLabel2
    }

    state: "verticalPanel"
    states: [
        State {
            name: "horizontalPanel"
            when: plasmoid.formFactor == PlasmaCore.Types.Horizontal

            PropertyChanges { target: clock
                targetHeight: clock.horizontalHeight
                width: clock.fixedWidth
                Layout.minimumWidth: clock.fixedWidth
                Layout.preferredWidth: clock.fixedWidth
            }
            PropertyChanges { target: timeContainer1
                width: clock.fixedWidth
                height: clock.lineHeight1
            }
            PropertyChanges { target: timeContainer2
                width: clock.fixedWidth
                height: clock.lineHeight2
            }
        },

        State {
            name: "verticalPanel"
            when: plasmoid.formFactor == PlasmaCore.Types.Vertical

            PropertyChanges { target: clock
                targetHeight: clock.verticalHeight
                Layout.minimumHeight: clock.targetHeight
                Layout.preferredHeight: clock.targetHeight
            }
            PropertyChanges { target: timeContainer1
                width: clock.width
                height: clock.lineHeight1
            }
            PropertyChanges { target: timeContainer2
                width: clock.width
                height: clock.lineHeight2
            }
            PropertyChanges { target: timeLabel1
                width: timeContainer1.width
                fontSizeMode: Text.HorizontalFit
            }
            PropertyChanges { target: timeLabel2
                width: timeContainer2.width
                fontSizeMode: Text.HorizontalFit
            }
        },

        State {
            name: "floating"
            when: plasmoid.formFactor == PlasmaCore.Types.Planar

            PropertyChanges { target: clock
                targetHeight: clock.verticalFixedLineHeight
                width: clock.horizontalFixedLineWidth
                Layout.preferredWidth: clock.horizontalFixedLineWidth
                height: clock.targetHeight
                Layout.preferredHeight: clock.targetHeight
            }
            PropertyChanges { target: timeContainer1
                width: clock.width
                height: clock.lineHeight1
            }
            PropertyChanges { target: timeContainer2
                width: clock.width
                height: clock.lineHeight2
            }
            PropertyChanges { target: timeLabel1
                width: timeContainer1.width
                fontSizeMode: Text.HorizontalFit
            }
            PropertyChanges { target: timeLabel2
                width: timeContainer2.width
                fontSizeMode: Text.HorizontalFit
            }
        }
    ]
}
