import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15 as QQC2
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.kirigami 2.20 as Kirigami
import org.kde.plasma.plasmoid 2.0

PlasmaComponents.Control {
    id: colorGrid
    Layout.fillWidth: true

    property alias colors: colorRepeater.model
    property color selectedColor: colors ? colors[0] : "transparent"
    
    background: Rectangle {
        color: Kirigami.Theme.backgroundColor
        opacity: 0.2
        radius: Kirigami.Units.smallSpacing
    }

    contentItem: GridLayout {
        id: content
        columns: Math.floor(width / (Kirigami.Units.gridUnit * 4))
        rowSpacing: Kirigami.Units.smallSpacing
        columnSpacing: Kirigami.Units.smallSpacing

        Repeater {
            id: colorRepeater
            
            delegate: QQC2.Button {
                id: colorButton
                Layout.fillWidth: true
                Layout.preferredHeight: width
                
                background: Rectangle {
                    color: modelData
                    radius: Kirigami.Units.smallSpacing
                    border.width: colorButton.checked ? 2 : 1
                    border.color: colorButton.checked ? 
                        Kirigami.Theme.highlightColor : 
                        Kirigami.Theme.textColor
                }
                
                checkable: true
                checked: colorGrid.selectedColor === modelData
                
                onClicked: {
                    colorGrid.selectedColor = modelData
                }
                
                QQC2.ToolTip {
                    text: modelData
                    visible: colorButton.hovered
                    delay: Kirigami.Units.toolTipDelay
                }
            }
        }
    }
}
