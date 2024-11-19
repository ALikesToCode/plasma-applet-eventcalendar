import QtQuick
import org.kde.plasma.networkmanagement as PlasmaNM
import org.kde.kirigami as Kirigami

Item {
    id: networkStatusItem
    
    property string networkStatus: plasmaNMStatus.networkStatus
    
    function reload() {
        // Force a status update
        plasmaNMStatus.networkStatusChanged()
    }

    PlasmaNM.NetworkStatus {
        id: plasmaNMStatus
        onNetworkStatusChanged: {
            // Emit the status change
            networkStatusItem.networkStatus = networkStatus
        }
    }

    // Error handling
    Connections {
        target: plasmaNMStatus
        function onErrorOccurred(error) {
            console.error("Network status error:", error)
        }
    }
}
