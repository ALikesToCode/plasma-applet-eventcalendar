import QtQuick 2.15
import org.kde.plasma.plasmoid 2.0
import org.kde.kirigami 2.20 as Kirigami
import org.kde.notification 1.0

import "./lib"

QtObject {
    id: notificationManager
    
    // Use Plasma 6 notification manager
    property var notificationInterface: Notification {
        id: notification
    }

    property var executable: ExecUtil { id: executable }

    function notify(args, callback) {
        // Log notification request
        logger.debugJSON('NotificationManager.notify', args)
        
        // Set up notification properties
        notification.title = args.summary || ""
        notification.text = args.body || ""
        notification.iconName = args.appIcon || ""
        notification.applicationName = args.appName || ""
        notification.timeout = args.expireTimeout || -1
        
        // Handle sound
        if (args.sound || args.soundFile) {
            notification.soundFile = args.sound || args.soundFile
            notification.playSound = true
            notification.loopSound = args.loop || false
        }

        // Add actions
        if (args.actions) {
            notification.actions = args.actions
        }

        // Set metadata
        notification.setMetadata("timestamp", Date.now())

        // Connect to action invoked signal
        notification.actionInvoked.connect(function(actionId) {
            if (typeof callback === 'function') {
                callback(actionId)
            }
        })

        // Show notification
        notification.show()
    }
}
