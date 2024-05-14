import QtQuick 2.15
import QtQuick.Layouts 1.15
import org.kde.plasma.core 2.0 as PlasmaCore

ColumnLayout {
    id: eventDialogIcon
    Layout.fillHeight: true

    property alias source: iconItem.source
    property int size: PlasmaCore.Units.iconSizes.smallMedium

    PlasmaCore.Icon {
        id: iconItem
        Layout.alignment: Qt.AlignVCenter

        implicitWidth: eventDialogIcon.size
        implicitHeight: eventDialogIcon.size
    }
}
