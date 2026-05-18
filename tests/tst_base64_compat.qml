import QtQml

import "../package/contents/ui/lib/Base64Compat.js" as Base64Compat

QtObject {
	Component.onCompleted: {
		var input = "plain ascii and Bhilai \u2600 \ud83d\udcc5"
		var encoded = Base64Compat.base64EncodeString(input)
		var decoded = Base64Compat.base64DecodeToString(encoded)
		if (decoded !== input) {
			console.error("Base64 roundtrip mismatch", decoded)
			Qt.exit(1)
			return
		}
		Qt.exit(0)
	}
}
