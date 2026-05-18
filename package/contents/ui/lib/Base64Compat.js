.pragma library

var BASE64_ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

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

function arrayLikeToBytes(value) {
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
	var normalized = arrayLikeToBytes(bytes)
	var output = ""
	for (var i = 0; i < normalized.length; i += 3) {
		var b1 = normalized[i]
		var hasB2 = i + 1 < normalized.length
		var hasB3 = i + 2 < normalized.length
		var b2 = hasB2 ? normalized[i + 1] : 0
		var b3 = hasB3 ? normalized[i + 2] : 0
		var triplet = (b1 << 16) | (b2 << 8) | b3

		output += BASE64_ALPHABET[(triplet >> 18) & 0x3F]
		output += BASE64_ALPHABET[(triplet >> 12) & 0x3F]
		output += hasB2 ? BASE64_ALPHABET[(triplet >> 6) & 0x3F] : "="
		output += hasB3 ? BASE64_ALPHABET[triplet & 0x3F] : "="
	}
	return output
}

function base64DecodeBytes(value) {
	var input = String(value).replace(/[\r\n\t ]/g, "")
	var bytes = []
	for (var i = 0; i < input.length; i += 4) {
		var c1 = BASE64_ALPHABET.indexOf(input.charAt(i))
		var c2 = BASE64_ALPHABET.indexOf(input.charAt(i + 1))
		var c3Char = input.charAt(i + 2)
		var c4Char = input.charAt(i + 3)
		var c3 = c3Char === "=" ? 0 : BASE64_ALPHABET.indexOf(c3Char)
		var c4 = c4Char === "=" ? 0 : BASE64_ALPHABET.indexOf(c4Char)
		if (c1 < 0 || c2 < 0 || (c3Char !== "=" && c3 < 0) || (c4Char !== "=" && c4 < 0)) {
			throw new Error("Invalid base64 data")
		}

		var triplet = (c1 << 18) | (c2 << 12) | (c3 << 6) | c4
		bytes.push((triplet >> 16) & 0xFF)
		if (c3Char !== "=") {
			bytes.push((triplet >> 8) & 0xFF)
		}
		if (c4Char !== "=") {
			bytes.push(triplet & 0xFF)
		}
	}
	return bytes
}

function base64EncodeString(value) {
	return base64EncodeBytes(stringToUtf8Bytes(value))
}

function base64DecodeToString(value) {
	return bytesToUtf8String(base64DecodeBytes(value))
}
