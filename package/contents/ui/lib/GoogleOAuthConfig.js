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

// The built-in client is a Desktop app client in the "plasma-eventcalendar"
// Google Cloud project. Google tells installed apps to embed the client
// secret in their source, where it "is obviously not treated as a secret":
// https://developers.google.com/identity/protocols/oauth2#installed
// Google's token endpoint still requires it, so it ships with the widget.
// Every sign-in also uses PKCE, so a stolen authorization code is useless.
var builtInClientId = "699005155185-1pdeeof2mmr0q85cnklr3up1st7l6h3r.apps.googleusercontent.com"
var builtInClientSecret = "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"

function normalizedClientValue(value) {
	return value ? String(value).trim() : ""
}

// The secret to send for a client. A user can enter the built-in client ID
// without its secret, so fill that in.
function clientSecretFor(clientId, clientSecret) {
	var secret = normalizedClientValue(clientSecret)
	if (!secret && normalizedClientValue(clientId) === builtInClientId) {
		return builtInClientSecret
	}
	return secret
}

// Picks the client to sign in with:
// 1. the user's own client, when they entered a client ID;
// 2. a client stored with its secret by an older version, unless the user
//    chose the built-in client instead;
// 3. the built-in client.
function effectiveClientCredentials(config) {
	config = config || {}
	var customId = normalizedClientValue(config.customClientId)
	var latestId = normalizedClientValue(config.latestClientId)
	var latestSecret = normalizedClientValue(config.latestClientSecret)
	var useDesktopClient = config.useDesktopClient === true

	if (customId) {
		return {
			clientId: customId,
			clientSecret: clientSecretFor(customId, config.customClientSecret),
		}
	}
	if (!useDesktopClient && latestId && latestSecret) {
		return {
			clientId: latestId,
			clientSecret: latestSecret,
		}
	}
	return {
		clientId: builtInClientId,
		clientSecret: builtInClientSecret,
	}
}

function authConfigurationError(clientId) {
	if (!normalizedClientValue(clientId)) {
		return "Missing Google OAuth client ID."
	}
	return ""
}

if (typeof module !== "undefined") {
	module.exports = {
		requestedScopes: requestedScopes,
		authorizationScope: authorizationScope,
		builtInClientId: builtInClientId,
		builtInClientSecret: builtInClientSecret,
		clientSecretFor: clientSecretFor,
		effectiveClientCredentials: effectiveClientCredentials,
		authConfigurationError: authConfigurationError,
		normalizedClientValue: normalizedClientValue,
	}
}
