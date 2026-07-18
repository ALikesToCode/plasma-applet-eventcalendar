from __future__ import annotations

import datetime
import importlib.util
import json
import pathlib
import unittest
from unittest import mock

from icalendar import Calendar


SCRIPT_PATH = pathlib.Path(__file__).parents[1] / "package/contents/scripts/icsjson.py"
SPEC = importlib.util.spec_from_file_location("eventcalendar_icsjson", SCRIPT_PATH)
icsjson = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(icsjson)


def parse_calendar(events: str) -> Calendar:
	return Calendar.from_ical(
		("BEGIN:VCALENDAR\r\nVERSION:2.0\r\n" + events + "END:VCALENDAR\r\n").encode()
	)


class IcsJsonTests(unittest.TestCase):
	def test_timezone_aware_values_are_normalized_to_local_naive_time(self):
		aware = datetime.datetime(2026, 7, 3, 0, 30, tzinfo=datetime.timezone.utc)
		expected = aware.astimezone().replace(tzinfo=None)

		self.assertEqual(icsjson.ensure_date_time(aware), expected)

	def test_event_filter_uses_half_open_bounds(self):
		calendar = parse_calendar(
			"BEGIN:VEVENT\r\n"
			"UID:boundary-test\r\n"
			"DTSTART:20260703T100000Z\r\n"
			"DTEND:20260703T110000Z\r\n"
			"SUMMARY:Boundary test\r\n"
			"END:VEVENT\r\n"
		)
		event = calendar.walk("vevent")[0]
		start = icsjson.ensure_date_time(event["DTSTART"].dt)
		end = icsjson.ensure_date_time(event["DTEND"].dt)

		self.assertTrue(icsjson.event_within(event, start, end))
		self.assertFalse(icsjson.event_within(event, end, end + datetime.timedelta(hours=1)))
		self.assertFalse(icsjson.event_within(event, start - datetime.timedelta(hours=1), start))

	def test_zero_duration_event_is_included_at_its_start(self):
		calendar = parse_calendar(
			"BEGIN:VEVENT\r\n"
			"UID:instant-test\r\n"
			"DTSTART:20260703T100000Z\r\n"
			"SUMMARY:Instant test\r\n"
			"END:VEVENT\r\n"
		)
		event = calendar.walk("vevent")[0]
		start = icsjson.ensure_date_time(event["DTSTART"].dt)

		self.assertTrue(
			icsjson.event_within(event, start, start + datetime.timedelta(seconds=1))
		)

	def test_query_delegates_expansion_to_recurring_ical_events(self):
		calendar = parse_calendar(
			"BEGIN:VEVENT\r\n"
			"UID:delegation-test\r\n"
			"DTSTART:20260703T100000Z\r\n"
			"DTEND:20260703T110000Z\r\n"
			"SUMMARY:Delegation test\r\n"
			"END:VEVENT\r\n"
		)
		event = calendar.walk("vevent")[0]
		start = datetime.datetime(2026, 7, 1)
		end = datetime.datetime(2026, 7, 5)
		query = mock.Mock()
		query.between.return_value = [event]
		dependency = mock.Mock()
		dependency.of.return_value = query
		manager = icsjson.CalendarManager("unused")
		manager.cal = calendar

		with mock.patch.object(icsjson, "recurring_ical_events", dependency):
			self.assertEqual(list(manager.query(start, end)), [event])

		dependency.of.assert_called_once_with(calendar)
		query.between.assert_called_once_with(start, end)

	@unittest.skipUnless(
		icsjson.recurring_ical_events is not None,
		"recurring-ical-events is not installed",
	)
	def test_recurring_events_apply_exdates_and_overrides(self):
		calendar = parse_calendar(
			"BEGIN:VEVENT\r\n"
			"UID:daily-test\r\n"
			"DTSTART:20260701T100000Z\r\n"
			"DTEND:20260701T110000Z\r\n"
			"RRULE:FREQ=DAILY;COUNT=4\r\n"
			"EXDATE:20260702T100000Z\r\n"
			"SUMMARY:Daily test\r\n"
			"END:VEVENT\r\n"
			"BEGIN:VEVENT\r\n"
			"UID:daily-test\r\n"
			"RECURRENCE-ID:20260703T100000Z\r\n"
			"DTSTART:20260703T120000Z\r\n"
			"DTEND:20260703T130000Z\r\n"
			"SUMMARY:Moved occurrence\r\n"
			"END:VEVENT\r\n"
		)
		manager = icsjson.CalendarManager("unused")
		manager.cal = calendar

		events = list(manager.query(
			datetime.datetime(2026, 7, 1),
			datetime.datetime(2026, 7, 5),
		))
		payload = json.loads(icsjson.events_to_json(events))

		self.assertEqual(len(events), 3)
		self.assertEqual(
			[item["summary"] for item in payload["items"]],
			["Daily test", "Moved occurrence", "Daily test"],
		)
		self.assertEqual(len({item["id"] for item in payload["items"]}), 3)


if __name__ == "__main__":
	unittest.main()
