import QtQuick
import org.kde.plasma.components as PlasmaComponents

PlasmaComponents.Menu {
	id: contextMenu

	signal populate(var contextMenu)

	// Force loading of MenuItem.qml so dynamic creation *should* be synchronous.
	// It's a property since the default content property of PlasmaComponent.ContextMenu doesn't like it.
	property var menuItemComponent: Component {
		MenuItem {}
	}
	property var menuSeparatorComponent: Component {
		PlasmaComponents.MenuSeparator {}
	}

	function newSeperator(parentMenu) {
		return menuSeparatorComponent.createObject(null)
	}

	function newMenuItem(parentMenu, properties) {
		return menuItemComponent.createObject(null, properties || {})
	}

	function newSubMenu(parentMenu, properties) {
		var targetMenu = parentMenu || contextMenu
		var subMenu = Qt.createComponent("ContextMenu.qml").createObject(targetMenu)
		targetMenu.addMenu(subMenu)
		return subMenu
	}

	function addMenuItem(item) {
		if (item) {
			addItem(item)
		}
	}

	function clearMenuItems() {
		for (var i = contentData.length - 1; i >= 0; i--) {
			if (contentData[i]) {
				contentData[i].destroy()
			}
		}
	}

	function loadMenu() {
		clearMenuItems()
		populate(contextMenu)
	}

	function show(x, y) {
		loadMenu()
		if (contentData.length > 0) {
			var position = parent ? parent.mapToItem(null, x, y) : Qt.point(x, y)
			popup(position.x, position.y)
		}
	}
}
