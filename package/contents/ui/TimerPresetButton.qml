import org.kde.ksvg 1.0 as KSvg
import QtQuick 2.0
import QtQuick.Layouts 1.0
import org.kde.kirigami 2.15 as Kirigami

// https://github.com/KDE/plasma-framework/blob/master/src/declarativeimports/plasmacomponents3/Button.qml#L35
PlasmaComponents3.Button {
	// PlasmaComponents3.Button already sets Layout.minimumWidth since KF5 v5.68
	Layout.preferredWidth: appletConfig.timerButtonWidth
}
