.pragma library

var MAX_BASE64_JSON_LENGTH = 1024 * 1024

function isDangerousKey(key) {
	return key === "__proto__" || key === "constructor" || key === "prototype"
}

function validateJsonValue(value) {
	if (value === null || typeof value !== "object") {
		return
	}

	if (Array.isArray(value)) {
		for (var i = 0; i < value.length; i++) {
			validateJsonValue(value[i])
		}
		return
	}

	var keys = Object.keys(value)
	for (var j = 0; j < keys.length; j++) {
		var key = keys[j]
		if (isDangerousKey(key)) {
			throw new Error("Dangerous key in config JSON: " + key)
		}
		validateJsonValue(value[key])
	}
}

function parseBase64Json(configValue, defaultValue) {
	if (!configValue) {
		return defaultValue
	}

	var decoded = Qt.atob(configValue)
	if (decoded.length > MAX_BASE64_JSON_LENGTH) {
		throw new Error("Config payload exceeds maximum size")
	}

	var parsed = JSON.parse(decoded)
	validateJsonValue(parsed)
	return parsed
}

function serializeBase64Json(value) {
	var normalizedValue = typeof value === "undefined" ? null : value
	var serialized = JSON.stringify(normalizedValue)
	if (serialized.length > MAX_BASE64_JSON_LENGTH) {
		throw new Error("Config payload exceeds maximum size")
	}
	return Qt.btoa(serialized)
}
