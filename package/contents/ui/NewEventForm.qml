import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.kirigami 2.20 as Kirigami

Loader {
    id: newEventForm
    active: false
    visible: active

    sourceComponent: Component {
        RowLayout {
            spacing: Kirigami.Units.smallSpacing

            PlasmaComponents3.CheckBox {
                Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
                Layout.preferredHeight: calendarSelector.implicitHeight
                enabled: false
                visible: calendarSelector.selectedIsTasklist
            }

            Rectangle {
                Layout.preferredWidth: appletConfig.eventIndicatorWidth
                Layout.fillHeight: true
                color: calendarSelector.selectedCalendar?.backgroundColor || Kirigami.Theme.textColor
            }

            ColumnLayout {
                spacing: Kirigami.Units.largeSpacing

                Component.onCompleted: {
                    newEventText.forceActiveFocus()
                    newEventFormOpened(model, calendarSelector)
                }

                CalendarSelector {
                    id: calendarSelector
                    Layout.fillWidth: true
                }

                RowLayout {
                    PlasmaComponents3.TextField {
                        id: newEventText
                        Layout.fillWidth: true
                        placeholderText: i18n("Eg: 9am-5pm Work")
                        Kirigami.FormData.label: i18n("Event Details")
                        
                        onAccepted: {
                            const calendarEntry = calendarSelector.model[calendarSelector.currentIndex]
                            const calendarId = calendarEntry.calendarId
                            if (calendarId && date && text) {
                                submitNewEventForm(calendarId, date, text)
                                text = ''
                            }
                        }
                        
                        Keys.onEscapePressed: {
                            newEventForm.active = false
                        }
                    }
                }
            }
        }
    }
}
