import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.kirigami 2.20 as Kirigami
import org.kde.plasma.plasmoid 2.0

Item {
    id: root
    implicitWidth: mainLayout.implicitWidth
    implicitHeight: mainLayout.implicitHeight

    // Properties bound to configuration
    property string version: "?"
    property string metadataFilepath: plasmoid.file("", "../metadata.desktop")
    property alias showDetails: detailsButton.checked

    Plasmoid.backgroundHints: PlasmaCore.Types.DefaultBackground

    // Main layout using modern components
    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        spacing: Kirigami.Units.smallSpacing

        PlasmaComponents.Label {
            id: label
            Layout.fillWidth: true
            text: i18n("<b>Version:</b> %1", version)
            wrapMode: Text.WordWrap
            color: Kirigami.Theme.textColor
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            PlasmaComponents.Button {
                id: detailsButton
                text: i18n("Show Details")
                checkable: true
                icon.name: "view-more-symbolic"
                Layout.alignment: Qt.AlignLeft
            }

            PlasmaComponents.Button {
                text: i18n("Refresh")
                icon.name: "view-refresh-symbolic"
                onClicked: root.refreshVersion()
                Layout.alignment: Qt.AlignRight
            }
        }

        // Details section
        Loader {
            Layout.fillWidth: true
            active: detailsButton.checked
            visible: active
            sourceComponent: ColumnLayout {
                spacing: Kirigami.Units.smallSpacing
                
                PlasmaComponents.Label {
                    text: i18n("Metadata Path: %1", metadataFilepath)
                    wrapMode: Text.WordWrap
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    color: Kirigami.Theme.disabledTextColor
                }
            }
        }
    }

    // Version reader using modern DataSource
    PlasmaCore.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []

        onNewData: {
            var exitCode = data["exit code"]
            var stdout = data["stdout"]
            if (exitCode === 0) {
                version = stdout.replace('\n', ' ').trim()
            } else {
                version = i18n("Error reading version")
            }
            disconnectSource(sourceName)
        }

        function exec(cmd) {
            connectSource(cmd)
        }
    }

    function refreshVersion() {
        var cmd = 'kreadconfig5 --file "' + metadataFilepath + 
                  '" --group "Desktop Entry" --key "X-KDE-PluginInfo-Version"'
        executable.exec(cmd)
    }

    Component.onCompleted: {
        refreshVersion()
    }
}
