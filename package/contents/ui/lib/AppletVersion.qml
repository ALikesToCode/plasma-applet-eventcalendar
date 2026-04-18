import QtQuick
import QtQuick.Controls

Item {
	implicitWidth: label.implicitWidth
	implicitHeight: label.implicitHeight

	property string version: "?"
	property string metadataFilepath: {
		var path = Qt.resolvedUrl("../../metadata.json").toString()
		return path.indexOf("file://") === 0 ? path.slice(7) : path
	}

	ExecUtil {
		id: executable
	}

	Label {
		id: label
		text: i18n("<b>Version:</b> %1", version)
	}

	Component.onCompleted: {
		executable.exec([
			"python3",
			"-c",
			"import json,sys; print(json.load(open(sys.argv[1]))['KPlugin']['Version'])",
			metadataFilepath,
		], function(cmd, exitCode, exitStatus, stdout) {
			if (exitCode === 0) {
				version = executable.trimOutput(stdout)
			}
		})
	}
}
