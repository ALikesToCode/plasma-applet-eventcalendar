import QtQuick 2.15
import QtQuick.Layouts 1.15
import org.kde.plasma.plasmoid 2.0
import org.kde.kirigami 2.20 as Kirigami

PlasmoidItem {
    id: eventColorsBarColor

    Item {
        anchors.left: eventColorsBarColor.left
        anchors.right: eventColorsBarColor.right
        anchors.bottom: eventColorsBarColor.bottom
        height: parent.height / 8
        
        property bool usePadding: !plasmoid.configuration.monthShowBorder
        anchors.leftMargin: usePadding ? parent.width/8 : 0
        anchors.rightMargin: usePadding ? parent.width/8 : 0
        anchors.bottomMargin: usePadding ? parent.height/16 : 0

        RowLayout {
            anchors.fill: parent
            spacing: 0

            Repeater {
                model: dayStyle.useHighlightColor ? [Kirigami.Theme.highlightColor] : dayStyle.eventColors

                Rectangle {
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    color: modelData

                    Rectangle {
                        anchors.fill: parent
                        color: "transparent"
                        border.width: 1
                        border.color: Kirigami.Theme.backgroundColor
                        opacity: 0.5
                    }
                }
            }
        }
    }
}
