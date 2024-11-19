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
import QtQuick.Layouts 1.15
import org.kde.plasma.plasmoid 2.0
import org.kde.kirigami 2.20 as Kirigami
import org.kde.plasma.components 3.0 as PlasmaComponents3

Item {
    id: clockView

    property int lineHeight: parent.height
    property int lineSpacing: 0

    Layout.minimumWidth: clockLabel.implicitWidth
    Layout.minimumHeight: clockLabel.implicitHeight

    PlasmaComponents3.Label {
        id: clockLabel
        anchors.fill: parent
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: {
            if (plasmoid.configuration.clockShowLine2) {
                return Qt.formatDateTime(timeModel.currentTime, appletConfig.line1TimeFormat) + '\n' +
                       Qt.formatDateTime(timeModel.currentTime, appletConfig.line2TimeFormat)
            } else {
                return Qt.formatDateTime(timeModel.currentTime, appletConfig.line1TimeFormat)
            }
        }
        font {
            family: appletConfig.clockFontFamily
            weight: appletConfig.lineWeight1
            pixelSize: {
                if (plasmoid.configuration.clockMaxHeight > 0) {
                    return plasmoid.configuration.clockMaxHeight
                } else {
                    // Scale font to fit height
                    return parent.height
                }
            }
        }
        fontSizeMode: Text.VerticalFit
        wrapMode: Text.NoWrap
        smooth: true
    }

    TimeFormatSizeHelper {
        id: timeFormatSizeHelper
        timeLabel: clockLabel
    }
}
