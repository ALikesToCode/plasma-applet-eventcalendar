import QtQuick 2.15
import QtQuick.Layouts 1.15
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.kirigami 2.20 as Kirigami

PlasmaComponents3.MenuItem {
    id: menuItem
    
    // Properties
    property var subMenu: undefined
    property bool hasSubMenu: subMenu !== undefined
    
    // Theme integration
    icon.width: Kirigami.Units.iconSizes.small
    icon.height: Kirigami.Units.iconSizes.small
    
    // Visual feedback on hover
    background: Rectangle {
        color: menuItem.hovered ? Kirigami.Theme.highlightColor : "transparent"
        opacity: menuItem.hovered ? 0.2 : 1.0
        Behavior on color {
            ColorAnimation { duration: Kirigami.Units.shortDuration }
        }
    }
    
    // Arrow indicator for submenus
    contentItem: RowLayout {
        spacing: Kirigami.Units.smallSpacing
        
        PlasmaComponents3.Label {
            Layout.fillWidth: true
            text: menuItem.text
            color: menuItem.hovered ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor
            elide: Text.ElideRight
        }
        
        Kirigami.Icon {
            Layout.alignment: Qt.AlignRight
            visible: menuItem.hasSubMenu
            source: "go-next-symbolic"
            width: Kirigami.Units.iconSizes.small
            height: Kirigami.Units.iconSizes.small
            color: menuItem.hovered ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor
        }
    }
    
    // Handle submenu opening
    onClicked: {
        if (hasSubMenu) {
            subMenu.popup()
        }
    }
}
