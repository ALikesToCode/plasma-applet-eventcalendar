import QtQuick
import QtQuick.Layouts
import QtTest

// Run: qmltestrunner -input tests/tst_tooltip_size.qml (Qt 6)
//
// Plasma 6.8's ToolTipDialog sizes its window from the main item's implicit
// size, and PlasmaWindow then calls setSize() on the main item with the
// window's current size. That window is shared by every tooltip, so the first
// setSize() can carry another tooltip's size, or a tiny one (issue #64).
TestCase {
	id: testCase
	name: "TooltipSize"
	when: windowShown

	QtObject {
		id: timeModel
		property var currentTime: new Date(2026, 10, 15, 9, 41, 7)
		property var dataSource: null
	}
	QtObject {
		id: plasmoid
		property var configuration: ({
			selectedTimeZones: ["Local", "Europe/London"],
			displayTimezoneAsCode: false,
		})
	}

	// Mirrors toolTipItem in package/contents/ui/main.qml.
	Loader {
		id: tooltipLoader

		Layout.minimumWidth: item ? item.implicitWidth : 0
		Layout.maximumWidth: item ? item.implicitWidth : 0
		Layout.minimumHeight: item ? item.implicitHeight : 0
		Layout.maximumHeight: item ? item.implicitHeight : 0

		source: "../package/contents/ui/TooltipView.qml"
	}

	function contentWidth() {
		return tooltipLoader.item.childrenRect.width
	}

	function contentHeight() {
		return tooltipLoader.item.childrenRect.height
	}

	function test_loader_keeps_its_implicit_size_when_a_window_resizes_it() {
		compare(tooltipLoader.status, Loader.Ready)
		verify(contentWidth() > 0, "the tooltip must lay out its time and date")
		verify(contentHeight() > 0, "the tooltip must lay out its time and date")

		// PlasmaWindow::updateMainItemGeometry() with a stale, tiny window.
		tooltipLoader.width = 2
		tooltipLoader.height = 2

		// ToolTipDialog::updateSize() reads these.
		verify(tooltipLoader.implicitWidth >= contentWidth(),
			"implicitWidth " + tooltipLoader.implicitWidth + " must fit the content width " + contentWidth())
		verify(tooltipLoader.implicitHeight >= contentHeight(),
			"implicitHeight " + tooltipLoader.implicitHeight + " must fit the content height " + contentHeight())
		compare(tooltipLoader.Layout.minimumWidth, tooltipLoader.implicitWidth)
		compare(tooltipLoader.Layout.minimumHeight, tooltipLoader.implicitHeight)

		// The window grows to the implicit size and resizes the item again.
		tooltipLoader.width = tooltipLoader.implicitWidth
		tooltipLoader.height = tooltipLoader.implicitHeight
		compare(tooltipLoader.item.width, tooltipLoader.implicitWidth)
		compare(tooltipLoader.item.height, tooltipLoader.implicitHeight)
		verify(tooltipLoader.implicitWidth >= contentWidth())
		verify(tooltipLoader.implicitHeight >= contentHeight())
	}
}
