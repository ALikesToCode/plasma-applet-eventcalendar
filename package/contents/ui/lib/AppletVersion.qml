import QtQuick 2.0
import QtQuick.Controls 1.0
import QtQuick.Layouts 1.0
import org.kde.plasma.plasmoid 2.0

Item {
	implicitWidth: label.implicitWidth
	implicitHeight: label.implicitHeight

	property string version: "?"
	property string metadataFilepath: plasmoid.file("", "../metadata.desktop")
	ExecUtil {
		id: executable
	}

	Label {
		id: label
		text: i18n("<b>Version:</b> %1", version)
	}

	Component.onCompleted: {
		executable.exec([
			'kreadconfig5',
			'--file',
			metadataFilepath,
			'--group',
			'Desktop Entry',
			'--key',
			'X-KDE-PluginInfo-Version',
		], function(cmd, exitCode, exitStatus, stdout) {
			if (exitCode === 0) {
				version = executable.trimOutput(stdout)
			}
		})
	}

}
