import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.kirigami as Kirigami

PlasmaComponents3.Button {
    // Follow Plasma 6 layout guidelines
    Layout.preferredWidth: appletConfig.timerButtonWidth
    Layout.minimumHeight: Kirigami.Units.gridUnit * 2
    
    // Ensure proper theme integration
    Kirigami.Theme.colorSet: Kirigami.Theme.Button
    
    // Add hover feedback
    hoverEnabled: true
    
    // Ensure proper focus handling
    focusPolicy: Qt.StrongFocus
    
    // Add accessibility properties
    Accessible.role: Accessible.Button
    Accessible.name: text || ""
    Accessible.description: tooltip || ""
}
