// The narrowest scopes that cover what the widget does. Google's OAuth
// verification rejects broader scopes than an app needs.
// - calendar.calendarlist.readonly: calendarList.list, to pick calendars.
// - calendar.events: list, get, quickAdd, update and delete events.
// - tasks: list task lists, and list, create, update and delete tasks.
var requestedScopes = [
	"https://www.googleapis.com/auth/calendar.calendarlist.readonly",
	"https://www.googleapis.com/auth/calendar.events",
	"https://www.googleapis.com/auth/tasks",
]

function authorizationScope() {
	return requestedScopes.join(" ")
}

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
		requestedScopes: requestedScopes,
		authorizationScope: authorizationScope,
		builtInClientUnavailableMessage: builtInClientUnavailableMessage,
		effectiveClientCredentials: effectiveClientCredentials,
		authConfigurationError: authConfigurationError,
		normalizedClientValue: normalizedClientValue,
	}
}
