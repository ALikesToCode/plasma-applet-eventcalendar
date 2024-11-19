import QtQuick 2.15
import QtQuick.Layouts 1.15
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.kirigami 2.20 as Kirigami

PlasmoidItem {
    id: root

    // Plasmoid configuration properties
    property bool showIcon: Plasmoid.configuration.showIcon
    property bool showText: Plasmoid.configuration.showText
    property string customText: Plasmoid.configuration.customText

    // Network status properties
    readonly property Loader plasmaNMStatusLoader: Loader {
        id: plasmaNMStatusLoader
        source: "NetworkMonitorPlasmaNM.qml"
    }

    readonly property var connectedMessages: [
        i18ndc("plasmanetworkmanagement-libs", "A network device is connected, but there is only link-local connectivity", "Connected"),
        i18ndc("plasmanetworkmanagement-libs", "A network device is connected, but there is only site-local connectivity", "Connected"),
        i18ndc("plasmanetworkmanagement-libs", "A network device is connected, with global network connectivity", "Connected"),
    ]

    readonly property string networkStatus: {
        if (plasmaNMStatusLoader.status == Loader.Ready) {
            return plasmaNMStatusLoader.item.networkStatus
        }
        return ''
    }

    readonly property bool isConnected: {
        if (plasmaNMStatusLoader.status == Loader.Error) {
            return true
        }
        return connectedMessages.indexOf(networkStatus) >= 0
    }

    Plasmoid.preferredRepresentation: Plasmoid.fullRepresentation

    // Main layout
    contentItem: ColumnLayout {
        spacing: Kirigami.Units.smallSpacing

        PlasmaCore.IconItem {
            Layout.alignment: Qt.AlignHCenter
            visible: root.showIcon
            source: root.isConnected ? "network-connect" : "network-disconnect"
            Layout.preferredWidth: Kirigami.Units.iconSizes.medium
            Layout.preferredHeight: Kirigami.Units.iconSizes.medium
        }

        PlasmaComponents3.Label {
            Layout.alignment: Qt.AlignHCenter
            visible: root.showText
            text: root.customText || (root.isConnected ? i18n("Connected") : i18n("Disconnected"))
            color: theme.textColor
        }

        PlasmaComponents3.Button {
            Layout.alignment: Qt.AlignHCenter
            text: i18n("Refresh")
            icon.name: "view-refresh"
            onClicked: {
                if (plasmaNMStatusLoader.status == Loader.Ready) {
                    plasmaNMStatusLoader.item.reload()
                }
            }
        }
    }

    // Configuration change handling
    onShowIconChanged: updateLayout()
    onShowTextChanged: updateLayout()
    onCustomTextChanged: updateLayout()
    onIsConnectedChanged: {
        logger.debug('NetworkMonitor.isConnected', isConnected)
        updateLayout()
    }

    function updateLayout() {
        // Trigger layout update when configuration changes
        contentItem.Layout.invalidate()
    }

    Component.onCompleted: {
        logger.debug('NetworkMonitor.isConnected', isConnected)
    }
}
