import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.kirigami 2.20 as Kirigami

PlasmaComponents.Frame {
    id: configSection
    Layout.fillWidth: true
    default property alias _contentChildren: content.data

    background: Rectangle {
        color: Kirigami.Theme.backgroundColor
        border.color: Kirigami.Theme.textColor
        border.width: 1
        radius: Kirigami.Units.smallSpacing
        opacity: 0.1
    }

    ColumnLayout {
        id: content
        anchors {
            left: parent.left
            right: parent.right
            margins: Kirigami.Units.smallSpacing
        }
        spacing: Kirigami.Units.smallSpacing

        // Modern handling of dynamic children
        onChildrenChanged: {
            for (let i = 0; i < children.length; ++i) {
                children[i].Layout.fillWidth = true
            }
        }

        Component.onDestruction: {
            while (children.length > 0) {
                children[children.length - 1].parent = configSection
            }
        }
    }
}
