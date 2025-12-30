import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.plasma.plasmoid

Item {
	implicitWidth: label.implicitWidth
	implicitHeight: label.implicitHeight

	property string version: "?"
	property string metadataFilepath: {
		var path = plasmoid.file("", "metadata.json")
		return path.indexOf("file://") === 0 ? path.slice(7) : path
	}

	Plasma5Support.DataSource {
		id: executable
		engine: "executable"
		connectedSources: []
		function onNewData(sourceName, data) {
			var exitCode = data["exit code"]
			var exitStatus = data["exit status"]
			var stdout = data["stdout"]
			var stderr = data["stderr"]
			exited(exitCode, exitStatus, stdout, stderr)
			disconnectSource(sourceName) // cmd finished
		}
		function exec(cmd) {
			connectSource(cmd)
		}
		signal exited(int exitCode, int exitStatus, string stdout, string stderr)
	}

	Connections {
		target: executable
		function onExited(exitCode, exitStatus, stdout, stderr) {
			version = stdout.replace('\n', ' ').trim()
		}
	}

	Label {
		id: label
		text: i18n("<b>Version:</b> %1", version)
	}

	Component.onCompleted: {
		var cmd = "python3 -c \"import json;print(json.load(open('" + metadataFilepath + "'))['KPlugin']['Version'])\""
		executable.exec(cmd)
	}

}
