import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.kirigami 2.20 as Kirigami

Item {
    id: root
    Plasmoid.backgroundHints: PlasmaCore.Types.DefaultBackground

    // Configuration properties that can be set via the settings
    property int refreshInterval: plasmoid.configuration.refreshInterval
    property string displayMode: plasmoid.configuration.displayMode
    
    // Example of dynamic data binding
    property int clickCount: 0

    ColumnLayout {
        anchors.fill: parent
        spacing: Kirigami.Units.smallSpacing

        Kirigami.Heading {
            Layout.alignment: Qt.AlignHCenter
            level: 2
            text: i18n("Interactive Widget")
            color: Kirigami.Theme.textColor
        }

        PlasmaCore.IconItem {
            Layout.alignment: Qt.AlignHCenter
            source: "applications-system"
            width: Kirigami.Units.iconSizes.huge
            height: width
            
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    clickCount++
                    clickFeedback.running = true
                }
            }
        }

        Kirigami.Label {
            Layout.alignment: Qt.AlignHCenter
            text: i18n("Clicks: %1", clickCount)
            color: Kirigami.Theme.textColor
        }

        PlasmaCore.ToolTipArea {
            Layout.fillWidth: true
            mainText: i18n("Example Widget")
            subText: i18n("Click the icon to interact")

            PlasmaComponents3.Button {
                anchors.horizontalCenter: parent.horizontalCenter
                text: i18n("Reset Counter")
                onClicked: clickCount = 0
            }
        }
    }

    Timer {
        id: clickFeedback
        interval: 200
        onTriggered: plasmoid.expanded = !plasmoid.expanded
    }

    Component.onCompleted: {
        plasmoid.setAction("configure", i18n("Configure..."), "configure")
    }
}
