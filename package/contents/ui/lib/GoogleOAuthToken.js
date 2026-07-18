function parseTokenResponse(data) {
	if (!data) {
		return null
	}
	if (typeof data === "object") {
		return data
	}
	try {
		var parsed = JSON.parse(String(data))
		return parsed && typeof parsed === "object" ? parsed : null
	} catch (e) {
		return null
	}
}

function requiresReauthorization(data) {
	var parsed = parseTokenResponse(data)
	return !!(parsed && parsed.error === "invalid_grant")
}

function refreshErrorMessage(fallbackErr, data) {
	var parsed = parseTokenResponse(data)
	if (requiresReauthorization(parsed)) {
		return "Google authorization expired or was revoked. Open Event Calendar Settings, select the account, and use Update Selected to reconnect it."
	}
	if (parsed && parsed.error_description) {
		return String(parsed.error_description)
	}
	if (parsed && parsed.error) {
		return "Google OAuth error: " + String(parsed.error)
	}
	return fallbackErr || "Google token refresh failed."
}

function errorSummary(data) {
	var parsed = parseTokenResponse(data)
	return {
		error: parsed && parsed.error ? String(parsed.error) : "",
		errorSubtype: parsed && parsed.error_subtype ? String(parsed.error_subtype) : "",
		hasDescription: !!(parsed && parsed.error_description),
	}
}

if (typeof module !== "undefined") {
	module.exports = {
		parseTokenResponse: parseTokenResponse,
		requiresReauthorization: requiresReauthorization,
		refreshErrorMessage: refreshErrorMessage,
		errorSummary: errorSummary,
	}
}
