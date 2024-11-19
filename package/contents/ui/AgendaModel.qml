import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.kirigami 2.20 as Kirigami

import "Shared.js" as Shared

Plasmoid.compactRepresentation: PlasmaComponents.Label {
    text: agendaModel.count > 0 ? agendaModel.get(0).events.length + " events today" : "No events"
}

Plasmoid.fullRepresentation: ColumnLayout {
    id: root
    spacing: Kirigami.Units.smallSpacing

    PlasmaComponents.ScrollView {
        Layout.fillWidth: true
        Layout.fillHeight: true

        ListView {
            id: agendaView
            model: ListModel {
                id: agendaModel
                property var eventModel
                property var timeModel

                dynamicRoles: false

                property bool populating: false

                property bool showDailyWeather: false

                property int showNextNumDays: Plasmoid.configuration.showNextNumDays
                property bool showAllDaysInMonth: Plasmoid.configuration.showAllDaysInMonth
                property bool clipPastEvents: Plasmoid.configuration.clipPastEvents
                property bool clipPastEventsToday: Plasmoid.configuration.clipPastEventsToday
                property bool clipEventsOutsideLimits: true
                property bool clipEventsFromOtherMonths: true
                property date visibleDateMin: new Date()
                property date visibleDateMax: new Date()
                property date currentMonth: new Date()

                // ... rest of the model implementation remains the same ...
            }

            delegate: Kirigami.AbstractListItem {
                contentItem: ColumnLayout {
                    PlasmaComponents.Label {
                        text: Qt.formatDate(date, "ddd MMM d")
                        font.bold: true
                    }

                    Repeater {
                        model: events
                        delegate: RowLayout {
                            PlasmaCore.IconItem {
                                source: "view-calendar-day"
                                Layout.preferredWidth: Kirigami.Units.iconSizes.small
                                Layout.preferredHeight: Kirigami.Units.iconSizes.small
                            }
                            PlasmaComponents.Label {
                                text: modelData.summary
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }
                    }

                    Kirigami.Separator {
                        Layout.fillWidth: true
                        visible: showDailyWeather
                    }

                    RowLayout {
                        visible: showDailyWeather
                        PlasmaCore.IconItem {
                            source: weatherIcon
                            Layout.preferredWidth: Kirigami.Units.iconSizes.small
                            Layout.preferredHeight: Kirigami.Units.iconSizes.small
                        }
                        PlasmaComponents.Label {
                            text: tempLow + "° - " + tempHigh + "°"
                        }
                    }
                }
            }
        }
    }

    PlasmaComponents.Button {
        text: "Refresh"
        icon.name: "view-refresh"
        onClicked: {
            // Trigger refresh of events
            parseGCalEvents(eventModel)
            if (showDailyWeather) {
                parseWeatherForecast(timeModel)
            }
        }
    }
}

Plasmoid.configurationRequired: false

Plasmoid.configuration: PlasmaCore.ConfigModel {
    ConfigCategory {
        name: i18n("General")
        icon: "configure"
        source: "configGeneral.qml"
    }
}
