.pragma library

var arrayLikeBase64Support = null

function stringToUtf8Bytes(value) {
	var stringValue = String(value)
	var bytes = []
	for (var i = 0; i < stringValue.length; i++) {
		var codePoint = stringValue.charCodeAt(i)
		if (codePoint >= 0xD800 && codePoint <= 0xDBFF && i + 1 < stringValue.length) {
			var low = stringValue.charCodeAt(i + 1)
			if (low >= 0xDC00 && low <= 0xDFFF) {
				codePoint = 0x10000 + ((codePoint - 0xD800) << 10) + (low - 0xDC00)
				i++
			}
		}

		if (codePoint < 0x80) {
			bytes.push(codePoint)
		} else if (codePoint < 0x800) {
			bytes.push(0xC0 | (codePoint >> 6))
			bytes.push(0x80 | (codePoint & 0x3F))
		} else if (codePoint < 0x10000) {
			bytes.push(0xE0 | (codePoint >> 12))
			bytes.push(0x80 | ((codePoint >> 6) & 0x3F))
			bytes.push(0x80 | (codePoint & 0x3F))
		} else {
			bytes.push(0xF0 | (codePoint >> 18))
			bytes.push(0x80 | ((codePoint >> 12) & 0x3F))
			bytes.push(0x80 | ((codePoint >> 6) & 0x3F))
			bytes.push(0x80 | (codePoint & 0x3F))
		}
	}
	return bytes
}

function bytesToUtf8String(bytes) {
	var text = ""
	for (var i = 0; i < bytes.length; i++) {
		var b1 = bytes[i]
		if (b1 < 0x80) {
			text += String.fromCharCode(b1)
			continue
		}

		if ((b1 & 0xE0) === 0xC0 && i + 1 < bytes.length) {
			var b2 = bytes[++i]
			text += String.fromCharCode(((b1 & 0x1F) << 6) | (b2 & 0x3F))
			continue
		}

		if ((b1 & 0xF0) === 0xE0 && i + 2 < bytes.length) {
			var b2 = bytes[++i]
			var b3 = bytes[++i]
			text += String.fromCharCode(((b1 & 0x0F) << 12) | ((b2 & 0x3F) << 6) | (b3 & 0x3F))
			continue
		}

		if ((b1 & 0xF8) === 0xF0 && i + 3 < bytes.length) {
			var b2 = bytes[++i]
			var b3 = bytes[++i]
			var b4 = bytes[++i]
			var codePoint = ((b1 & 0x07) << 18) | ((b2 & 0x3F) << 12) | ((b3 & 0x3F) << 6) | (b4 & 0x3F)
			codePoint -= 0x10000
			text += String.fromCharCode(0xD800 + (codePoint >> 10), 0xDC00 + (codePoint & 0x3FF))
			continue
		}

		text += "\uFFFD"
	}
	return text
}

function asciiStringToBytes(value) {
	var stringValue = String(value)
	var bytes = []
	for (var i = 0; i < stringValue.length; i++) {
		bytes.push(stringValue.charCodeAt(i) & 0xFF)
	}
	return bytes
}

function bytesToAsciiString(bytes) {
	var text = ""
	for (var i = 0; i < bytes.length; i++) {
		text += String.fromCharCode(bytes[i])
	}
	return text
}

function supportsArrayLikeBase64() {
	if (arrayLikeBase64Support !== null) {
		return arrayLikeBase64Support
	}
	try {
		arrayLikeBase64Support = bytesToAsciiString(arrayLikeToBytes(Qt.btoa([65]))) === "QQ=="
	} catch (e) {
		arrayLikeBase64Support = false
	}
	return arrayLikeBase64Support
}

function arrayLikeToBytes(value) {
	if (typeof value === "string") {
		return asciiStringToBytes(value)
	}

	if (typeof ArrayBuffer !== "undefined" && value instanceof ArrayBuffer) {
		return arrayLikeToBytes(new Uint8Array(value))
	}

	if (!value || typeof value.length !== "number") {
		return []
	}

	var bytes = []
	for (var i = 0; i < value.length; i++) {
		var item = value[i]
		bytes.push(typeof item === "string" ? item.charCodeAt(0) & 0xFF : item & 0xFF)
	}
	return bytes
}

function base64EncodeBytes(bytes) {
	if (!supportsArrayLikeBase64()) {
		return Qt.btoa(bytesToAsciiString(bytes))
	}
	return bytesToAsciiString(arrayLikeToBytes(Qt.btoa(bytes)))
}

function base64DecodeBytes(value) {
	if (!supportsArrayLikeBase64()) {
		return arrayLikeToBytes(Qt.atob(value))
	}
	return arrayLikeToBytes(Qt.atob(asciiStringToBytes(value)))
}

function base64EncodeString(value) {
	return base64EncodeBytes(stringToUtf8Bytes(value))
}

function base64DecodeToString(value) {
	return bytesToUtf8String(base64DecodeBytes(value))
}
