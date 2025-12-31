import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents3

// https://github.com/KDE/plasma-framework/blob/master/src/declarativeimports/plasmacomponents3/Button.qml#L35
PlasmaComponents3.Button {
	// PlasmaComponents3.Button already sets Layout.minimumWidth since KF5 v5.68
	Layout.preferredWidth: appletConfig.timerButtonWidth
}
