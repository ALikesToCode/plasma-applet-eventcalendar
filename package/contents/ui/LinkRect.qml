import QtQuick 2.15
import QtQuick.Layouts 1.15
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.kirigami 2.20 as Kirigami

import "lib"

Rectangle {
    id: linkRect
    width: implicitWidth
    height: implicitHeight
    implicitWidth: childrenRect.width
    implicitHeight: childrenRect.height
    
    // Theme-aware colors
    property color backgroundColor: Kirigami.Theme.backgroundColor
    property color backgroundHoverColor: Kirigami.Theme.highlightColor
    color: enabled && hovered ? Qt.rgba(backgroundHoverColor.r, 
                                      backgroundHoverColor.g, 
                                      backgroundHoverColor.b, 
                                      0.2) : backgroundColor
    
    // Tooltip properties
    property string tooltipMainText
    property string tooltipSubText
    property alias acceptedButtons: mouseArea.acceptedButtons
    property bool enabled: true
    readonly property alias hovered: mouseArea.containsMouse

    // Signals for interaction
    signal clicked(var mouse)
    signal leftClicked(var mouse)
    signal doubleClicked(var mouse)
    signal loadContextMenu(var contextMenu)
    
    Behavior on color {
        ColorAnimation {
            duration: Kirigami.Units.shortDuration
        }
    }
    
    PlasmaCore.ToolTipArea {
        id: tooltip
        anchors.fill: parent
        mainText: linkRect.tooltipMainText
        subText: linkRect.tooltipSubText
        interactive: true
        location: PlasmaCore.Types.BottomEdge

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: linkRect.enabled && containsMouse ? Qt.PointingHandCursor : Qt.ArrowCursor
            enabled: linkRect.enabled
            
            onClicked: {
                mouse.accepted = false
                linkRect.clicked(mouse)
                if (!mouse.accepted) {
                    if (mouse.button == Qt.LeftButton) {
                        linkRect.leftClicked(mouse)
                        PlasmaComponents3.ButtonFeedback.pressed()
                    } else if (mouse.button == Qt.RightButton) {
                        contextMenu.show(mouse.x, mouse.y)
                        mouse.accepted = true
                    }
                }
            }
            
            onDoubleClicked: {
                linkRect.doubleClicked(mouse)
                PlasmaComponents3.ButtonFeedback.pressed()
            }
        }
    }

    ContextMenu {
        id: contextMenu
        onPopulate: linkRect.loadContextMenu(contextMenu)
    }
}
