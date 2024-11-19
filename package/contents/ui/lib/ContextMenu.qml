import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.kirigami 2.20 as Kirigami

PlasmaComponents.Menu {
    id: contextMenu

    signal populate(var contextMenu)

    // Force loading of MenuItem.qml so dynamic creation is synchronous
    property var menuItemComponent: Component {
        PlasmaComponents.MenuItem {}
    }

    function newSeparator(parentMenu) {
        return newMenuItem(parentMenu, {
            separator: true
        })
    }

    function newMenuItem(parentMenu, properties) {
        return menuItemComponent.createObject(contextMenu, properties || {})
    }

    function newSubMenu(parentMenu, properties) {
        var subMenuItem = newMenuItem(parentMenu || contextMenu, properties)
        var subMenu = Qt.createComponent("ContextMenu.qml").createObject(contextMenu)
        subMenuItem.subMenu = subMenu
        subMenu.visualParent = subMenuItem.action
        return subMenuItem
    }

    function loadMenu() {
        contextMenu.clear()
        populate(contextMenu)
    }

    function show(x, y) {
        loadMenu()
        if (count > 0) {
            popup(x, y)
        }
    }

    // Ensure menu follows Plasma theme
    Kirigami.Theme.colorSet: Kirigami.Theme.View
    background: PlasmaCore.FrameSvgItem {
        imagePath: "widgets/background"
        enabledBorders: PlasmaCore.FrameSvgItem.AllBorders
    }
}
