function comparableDateValue(value) {
	if (value instanceof Date) {
		return value.getTime()
	}
	return value === undefined || value === null ? "" : String(value)
}

function sameEventTime(left, right) {
	left = left || {}
	right = right || {}
	return comparableDateValue(left.date) === comparableDateValue(right.date)
		&& comparableDateValue(left.dateTime) === comparableDateValue(right.dateTime)
}

function parsedEventId(event) {
	return event && (event.id || event.eventId || "")
}

function isSameParsedEvent(left, right) {
	return !!parsedEventId(left)
		&& parsedEventId(left) === parsedEventId(right)
		&& sameEventTime(left && left.start, right && right.start)
		&& sameEventTime(left && left.end, right && right.end)
		&& (left && left.summary || "") === (right && right.summary || "")
}

function dedupeParsedEvents(events) {
	if (!Array.isArray(events)) {
		return []
	}
	var deduped = []
	for (var i = 0; i < events.length; i++) {
		var event = events[i]
		var duplicate = false
		for (var j = 0; j < deduped.length; j++) {
			if (isSameParsedEvent(event, deduped[j])) {
				duplicate = true
				break
			}
		}
		if (!duplicate) {
			deduped.push(event)
		}
	}
	return deduped
}

if (typeof module !== "undefined") {
	module.exports = {
		comparableDateValue: comparableDateValue,
		dedupeParsedEvents: dedupeParsedEvents,
		isSameParsedEvent: isSameParsedEvent,
		parsedEventId: parsedEventId,
		sameEventTime: sameEventTime,
	}
}
