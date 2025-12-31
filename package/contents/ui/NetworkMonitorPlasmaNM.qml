import QtQuick
import org.kde.plasma.networkmanagement as PlasmaNM

PlasmaNM.NetworkStatus {
	id: plasmaNMStatus
	// onActiveConnectionsChanged: logger.debug('NetworkStatus.activeConnections', activeConnections)
	function onConnectivityChanged(connectivity) {
		logger.debug('NetworkStatus.connectivity', connectivity)
	}
	Component.onCompleted: {
		// logger.debug('NetworkStatus.activeConnections', activeConnections)
		logger.debug('NetworkStatus.connectivity', connectivity)
	}
}
