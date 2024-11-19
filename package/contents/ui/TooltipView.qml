import QtQuick 2.15
import QtQuick.Layouts 1.15
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.plasma.private.digitalclock 1.0 as DigitalClock
import org.kde.kirigami 2.20 as Kirigami

Item {
    id: tooltipContentItem

    property int preferredTextWidth: Kirigami.Units.gridUnit * 20

    width: childrenRect.width + Kirigami.Units.gridUnit
    height: childrenRect.height + Kirigami.Units.gridUnit

    LayoutMirroring.enabled: Qt.application.layoutDirection === Qt.RightToLeft
    LayoutMirroring.childrenInherit: true

    property var dataSource: timeModel.dataSource
    readonly property string timezoneTimeFormat: Qt.locale().timeFormat(Locale.ShortFormat)

    function timeForZone(zone) {
        var compactRepresentationItem = plasmoid.compactRepresentationItem
        if (!compactRepresentationItem) {
            return ""
        }

        try {
            // get the time for the given timezone from the dataengine
            var now = dataSource.data[zone]["DateTime"]
            // get current UTC time
            var msUTC = now.getTime() + (now.getTimezoneOffset() * 60000)
            // add the dataengine TZ offset to it
            var dateTime = new Date(msUTC + (dataSource.data[zone]["Offset"] * 1000))

            var formattedTime = Qt.formatTime(dateTime, timezoneTimeFormat)

            if (dateTime.getDay() !== dataSource.data["Local"]["DateTime"].getDay()) {
                formattedTime += " (" + Qt.formatDate(dateTime, Locale.ShortFormat) + ")"
            }

            return formattedTime
        } catch (e) {
            console.warn("Error formatting time for zone:", zone, e)
            return ""
        }
    }

    function nameForZone(zone) {
        try {
            if (plasmoid.configuration.displayTimezoneAsCode) {
                return dataSource.data[zone]["Timezone Abbreviation"]
            } else {
                return DigitalClock.TimezonesI18n.i18nCity(dataSource.data[zone]["Timezone City"])
            }
        } catch (e) {
            console.warn("Error getting name for zone:", zone, e)
            return zone
        }
    }

    ColumnLayout {
        id: columnLayout
        anchors {
            left: parent.left
            top: parent.top
            margins: Kirigami.Units.smallSpacing
        }
        spacing: Kirigami.Units.largeSpacing

        RowLayout {
            spacing: Kirigami.Units.largeSpacing

            Kirigami.Icon {
                id: tooltipIcon
                source: "preferences-system-time"
                Layout.alignment: Qt.AlignTop
                visible: true
                implicitWidth: Kirigami.Units.iconSizes.medium
                Layout.preferredWidth: implicitWidth
                Layout.preferredHeight: implicitWidth
            }

            ColumnLayout {
                spacing: 0

                PlasmaExtras.Heading {
                    id: tooltipMaintext
                    level: 3
                    Layout.minimumWidth: Math.min(implicitWidth, preferredTextWidth)
                    Layout.maximumWidth: preferredTextWidth
                    elide: Text.ElideRight
                    text: Qt.formatTime(timeModel.currentTime, Qt.locale().timeFormat(Locale.LongFormat))
                }

                PlasmaComponents3.Label {
                    id: tooltipSubtext
                    Layout.minimumWidth: Math.min(implicitWidth, preferredTextWidth)
                    Layout.maximumWidth: preferredTextWidth
                    text: Qt.formatDate(timeModel.currentTime, Qt.locale().dateFormat(Locale.LongFormat))
                    opacity: 0.6
                }
            }
        }

        GridLayout {
            id: timezoneLayout
            Layout.minimumWidth: Math.min(implicitWidth, preferredTextWidth)
            Layout.maximumWidth: preferredTextWidth
            columns: 2
            visible: timezoneRepeater.count > 0

            Repeater {
                id: timezoneRepeater
                model: {
                    try {
                        var timezones = []
                        for (var i = 0; i < plasmoid.configuration.selectedTimeZones.length; i++) {
                            var timezone = plasmoid.configuration.selectedTimeZones[i]
                            if (timezone !== 'Local') {
                                timezones.push(timezone)
                                timezones.push(timezone)
                            }
                        }
                        return timezones
                    } catch (e) {
                        console.warn("Error creating timezone model:", e)
                        return []
                    }
                }

                PlasmaComponents3.Label {
                    id: timezone
                    Layout.alignment: index % 2 === 0 ? Qt.AlignRight : Qt.AlignLeft

                    wrapMode: Text.NoWrap
                    text: index % 2 === 0 ? nameForZone(modelData) : timeForZone(modelData)
                    font.weight: index % 2 === 0 ? Font.Bold : Font.Normal
                    elide: Text.ElideNone
                    opacity: 0.6
                }
            }
        }
    }
}
