.pragma library

function escapeHtml(text) {
	if (typeof text === "undefined" || text === null) {
		return ""
	}
	return ("" + text)
		.replace(/\&/g, "&amp;")
		.replace(/\</g, "&lt;")
		.replace(/\>/g, "&gt;")
		.replace(/\"/g, "&quot;")
		.replace(/\'/g, "&#39;")
}

function isSafeExternalUrl(url) {
	if (typeof url !== "string") {
		return false
	}
	return /^(https?):\/\/[^\s]+$/i.test(url.trim())
}

function openExternalUrl(url) {
	if (!isSafeExternalUrl(url)) {
		console.warn("[eventcalendar] Refusing to open unsafe URL", url)
		return false
	}
	Qt.openUrlExternally(url.trim())
	return true
}

function openGoogleCalendarNewEventUrl(date) {
	function dateString(year, month, day) {
		var s = '' + year
		s += (month < 10 ? '0' : '') + month
		s += (day < 10 ? '0' : '') + day
		return s
	}

	var nextDay = new Date(date.getFullYear(), date.getMonth(), date.getDate() + 1)

	var url = 'https://calendar.google.com/calendar/render?action=TEMPLATE'
	var startDate = dateString(date.getFullYear(), date.getMonth() + 1, date.getDate())
	var endDate = dateString(nextDay.getFullYear(), nextDay.getMonth() + 1, nextDay.getDate())
	url += '&dates=' + startDate + '/' + endDate
	openExternalUrl(url)
}

function isSameDate(a, b) {
	// console.log('isSameDate', a, b)
	return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate()
}
function isDateEarlier(a, b) {
	var c = new Date(b.getFullYear(), b.getMonth(), b.getDate()) // midnight of date b
	return a < c
}
function isDateAfter(a, b) {
	var c = new Date(b.getFullYear(), b.getMonth(), b.getDate() + 1) // midnight of next day after b
	return a >= c
}
function dateTimeString(d) {
	return d.toISOString()
}
function dateString(d) {
	return d.toISOString().substr(0, 10)
}
function localeDateString(d) {
	return Qt.formatDateTime(d, 'yyyy-MM-dd')
}
function isValidDate(d) {
	if (d === null) {
		return false
	} else if (isNaN(d)) {
		return false
	} else {
		return true
	}
}

function renderText(text) {
	if (typeof text === 'undefined') {
		return ''
	}
	var rawText = "" + text
	var rUrl = /(https?:\/\/[^\s<]+)/gi
	var out = ''
	var lastIndex = 0
	var match
	while ((match = rUrl.exec(rawText)) !== null) {
		out += escapeHtml(rawText.slice(lastIndex, match.index))
		var href = match[0]
		if (!isSafeExternalUrl(href)) {
			out += escapeHtml(href)
		} else {
			out += '<a href="' + escapeHtml(href) + '">' + escapeHtml(href) + '</a>' + '&nbsp;'
		}
		lastIndex = match.index + href.length
	}
	out += escapeHtml(rawText.slice(lastIndex))

	// Remove leading new line, as Google sometimes adds them.
	out = out.replace(/\r\n?/g, '\n')
	out = out.replace(/\n/g, '<br>')
	out = out.replace(/^(\<br\>)+/, '')

	return out
}

// Merge values of objB into objA
function merge(objA, objB) {
	var keys = Object.keys(objB)
	for (var i = 0; i < keys.length; i++) {
		var key = keys[i]
		objA[key] = objB[key]
	}
}

// Remove keys from objA that are missing in objB
function removeMissingKeys(objA, objB) {
	var keys = Object.keys(objA)
	for (var i = 0; i < keys.length; i++) {
		var key = keys[i]
		if (typeof objB[key] === 'undefined') {
			delete objA[key]
		}
	}
}
