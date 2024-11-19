import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.kirigami 2.20 as Kirigami
import org.kde.plasma.plasmoid 2.0

PlasmaCore.Dialog {
    id: root
    flags: Qt.WindowStaysOnTopHint
    location: PlasmaCore.Types.TopEdge

    property var dateTime: new Date()
    property bool showTime: Plasmoid.configuration.showTime
    property string dateFormat: Plasmoid.configuration.dateFormat
    property string timeFormat: Plasmoid.configuration.timeFormat

    mainItem: ColumnLayout {
        spacing: Kirigami.Units.smallSpacing

        PlasmaComponents.Label {
            text: i18n("Current Date & Time")
            font.bold: true
            Layout.alignment: Qt.AlignHCenter
        }

        GridLayout {
            columns: 2
            columnSpacing: Kirigami.Units.smallSpacing
            rowSpacing: Kirigami.Units.smallSpacing

            PlasmaComponents.Label {
                text: i18n("Date:")
                Layout.alignment: Qt.AlignRight
            }

            PlasmaComponents.TextField {
                id: dateField
                text: Qt.formatDateTime(root.dateTime, root.dateFormat)
                enabled: false
                Layout.fillWidth: true
            }

            PlasmaComponents.Label {
                text: i18n("Time:")
                visible: root.showTime
                Layout.alignment: Qt.AlignRight
            }

            PlasmaComponents.TextField {
                id: timeField
                text: Qt.formatDateTime(root.dateTime, root.timeFormat)
                enabled: false
                visible: root.showTime
                Layout.fillWidth: true
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: Kirigami.Units.smallSpacing

            PlasmaComponents.Button {
                text: i18n("Previous Day")
                icon.name: "go-previous"
                onClicked: {
                    let oldDate = root.dateTime
                    root.dateTime = new Date(root.dateTime.setDate(root.dateTime.getDate() - 1))
                    root.dateTimeChanged(oldDate, -86400000, root.dateTime)
                }
            }

            PlasmaComponents.Button {
                text: i18n("Next Day")
                icon.name: "go-next"
                onClicked: {
                    let oldDate = root.dateTime
                    root.dateTime = new Date(root.dateTime.setDate(root.dateTime.getDate() + 1))
                    root.dateTimeChanged(oldDate, 86400000, root.dateTime)
                }
            }
        }
    }

    signal dateTimeChanged(date oldDateTime, int deltaDateTime, date newDateTime)

    Component.onCompleted: {
        Plasmoid.backgroundHints = PlasmaCore.Types.StandardBackground
        Plasmoid.configurationRequired = false
    }
}
