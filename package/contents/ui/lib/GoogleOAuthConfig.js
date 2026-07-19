var builtInClientUnavailableMessage = "The built-in Google OAuth client is currently rejected by Google because it requires a client secret. Add your own Google OAuth client ID, or switch back to a previously stored secret-based client."

function normalizedClientValue(value) {
	return value ? String(value).trim() : ""
}

function effectiveClientCredentials(config, defaultClientId) {
	config = config || {}
	var customId = normalizedClientValue(config.customClientId)
	var customSecret = normalizedClientValue(config.customClientSecret)
	var latestId = normalizedClientValue(config.latestClientId)
	var latestSecret = normalizedClientValue(config.latestClientSecret)
	var useDesktopClient = config.useDesktopClient === true

	if (customId) {
		return {
			clientId: customId,
			clientSecret: customSecret,
		}
	}
	if (!useDesktopClient && latestId) {
		return {
			clientId: latestId,
			clientSecret: latestSecret,
		}
	}
	return {
		clientId: defaultClientId,
		clientSecret: "",
	}
}

function authConfigurationError(clientId, clientSecret, defaultClientId) {
	if (!clientId) {
		return "Missing Google OAuth client ID."
	}
	if (!clientSecret && clientId === defaultClientId) {
		return builtInClientUnavailableMessage
	}
	return ""
}

if (typeof module !== "undefined") {
	module.exports = {
		builtInClientUnavailableMessage: builtInClientUnavailableMessage,
		effectiveClientCredentials: effectiveClientCredentials,
		authConfigurationError: authConfigurationError,
		normalizedClientValue: normalizedClientValue,
	}
}
