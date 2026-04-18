import argparse
import datetime
import hashlib
import ipaddress
import json
import socket
import urllib.parse
import urllib.request

from icalendar import Calendar

debugging = False
MAX_ICS_BYTES = 10 * 1024 * 1024
REQUEST_TIMEOUT = 15
ALLOWED_URL_SCHEMES = {"file", "http", "https"}
SAFE_REMOTE_SCHEMES = {"http", "https"}


def debug(*args):
	if debugging:
		print(*args)


def date_to_json(date_obj):
	if isinstance(date_obj.dt, datetime.datetime):
		return {"dateTime": date_obj.dt.isoformat()}
	return {"date": date_obj.dt.isoformat()}


def stringify(value):
	return "" if value is None else str(value)


def get_event_date(event, key):
	value = event.get(key)
	if value is None or not hasattr(value, "dt"):
		return None
	return value


def get_event_bounds(event):
	start = get_event_date(event, "DTSTART")
	if start is None:
		return None, None
	end = get_event_date(event, "DTEND") or start
	return start, end


def build_event_uid(event, start_date, end_date):
	uid = stringify(event.get("UID")).strip()
	if uid:
		return uid

	summary = stringify(event.get("SUMMARY")).strip()
	digest = hashlib.sha1(
		"|".join([
			start_date.dt.isoformat(),
			end_date.dt.isoformat(),
			summary,
		]).encode("utf-8", "ignore")
	).hexdigest()
	return digest


def events_to_json(event_list=None, indent=4):
	if event_list is None:
		event_list = []

	data = {"items": []}
	for event in event_list:
		start_date, end_date = get_event_bounds(event)
		if start_date is None or end_date is None:
			debug("Skipping event without DTSTART/DTEND", stringify(event.get("SUMMARY")))
			continue

		ical_uid = build_event_uid(event, start_date, end_date)
		item = {
			"kind": "calendar#event",
			"etag": "\"0123456789012345\"",
			"iCalUID": ical_uid,
			"id": "ics_{}_{}_{}".format(
				ical_uid,
				start_date.dt.isoformat(),
				end_date.dt.isoformat(),
			),
			"status": "confirmed",
			"htmlLink": "",
			"summary": stringify(event.get("SUMMARY")),
			"start": date_to_json(start_date),
			"end": date_to_json(end_date),
		}

		if "CREATED" in event and hasattr(event["CREATED"], "dt"):
			item["created"] = event["CREATED"].dt.isoformat()
		if "LAST-MODIFIED" in event and hasattr(event["LAST-MODIFIED"], "dt"):
			item["updated"] = event["LAST-MODIFIED"].dt.isoformat()
		if "LOCATION" in event:
			item["location"] = stringify(event.get("LOCATION"))

		data["items"].append(item)

	return json.dumps(data, indent=indent)


def ensure_date_time(dt):
	if isinstance(dt, datetime.date) and not isinstance(dt, datetime.datetime):
		return datetime.datetime.combine(dt, datetime.time.min)
	return dt


def event_within(event, start_time, end_time):
	event_start_date, event_end_date = get_event_bounds(event)
	if event_start_date is None or event_end_date is None:
		return False

	event_start = ensure_date_time(event_start_date.dt)
	event_end = ensure_date_time(event_end_date.dt)
	start_time = ensure_date_time(start_time)
	end_time = ensure_date_time(end_time)
	return event_start <= end_time and event_end >= start_time


def validate_remote_host(parsed_url):
	hostname = parsed_url.hostname
	if not hostname:
		raise ValueError("Remote calendar URL is missing a hostname")

	for family, _, _, _, sockaddr in socket.getaddrinfo(hostname, None):
		address = sockaddr[0]
		ip = ipaddress.ip_address(address)
		if (
			ip.is_private
			or ip.is_loopback
			or ip.is_link_local
			or ip.is_multicast
			or ip.is_reserved
			or ip.is_unspecified
		):
			raise ValueError("Refusing remote calendar URL that resolves to a local/private address")


def parse_calendar_url(raw_url):
	parsed = urllib.parse.urlparse(raw_url, scheme="file")
	scheme = parsed.scheme.lower()
	if scheme not in ALLOWED_URL_SCHEMES:
		raise ValueError("Unsupported calendar URL scheme: {}".format(parsed.scheme))

	if scheme == "file":
		if parsed.netloc not in ("", "localhost"):
			raise ValueError("Only local file calendar URLs are supported")
		return parsed

	validate_remote_host(parsed)
	return parsed


class SafeRedirectHandler(urllib.request.HTTPRedirectHandler):
	def redirect_request(self, req, fp, code, msg, headers, newurl):
		parsed = parse_calendar_url(newurl)
		if parsed.scheme not in SAFE_REMOTE_SCHEMES:
			raise ValueError("Redirected calendar URL must stay on http/https")
		return super().redirect_request(req, fp, code, msg, headers, newurl)


def read_calendar_bytes(parsed_url):
	if parsed_url.scheme == "file":
		path = urllib.request.url2pathname(parsed_url.path or "")
		if not path:
			raise ValueError("Calendar file path is empty")
		with open(path, "rb") as handle:
			data = handle.read(MAX_ICS_BYTES + 1)
	else:
		opener = urllib.request.build_opener(SafeRedirectHandler)
		request = urllib.request.Request(
			urllib.parse.urlunparse(parsed_url),
			headers={"User-Agent": "eventcalendar/1.0"},
		)
		with opener.open(request, timeout=REQUEST_TIMEOUT) as sock:
			data = sock.read(MAX_ICS_BYTES + 1)

	if len(data) > MAX_ICS_BYTES:
		raise ValueError("Calendar file exceeds size limit")
	return data


class CalendarManager:
	def __init__(self, url):
		self.url = url
		self.cal = None

	def read(self):
		parsed_url = parse_calendar_url(self.url)
		text = read_calendar_bytes(parsed_url)
		self.cal = Calendar.from_ical(text)

	@property
	def events(self):
		return self.cal.walk("vevent")

	def query(self, start_time, end_time):
		for event in self.events:
			if event_within(event, start_time, end_time):
				start_date, end_date = get_event_bounds(event)
				debug("within", start_date.dt, end_date.dt)
				yield event
			else:
				start_date, end_date = get_event_bounds(event)
				if start_date and end_date:
					debug("out", start_date.dt, end_date.dt)

	def to_json(self):
		return events_to_json(self.events)


def parse_date(date_str):
	return datetime.datetime.strptime(date_str, "%Y-%m-%d")


def argparse_date(value):
	try:
		return parse_date(value)
	except ValueError:
		msg = "Not a valid date: '{}'.".format(value)
		raise argparse.ArgumentTypeError(msg)


if __name__ == "__main__":
	parser = argparse.ArgumentParser(description="Read and query ICS calendar files")
	parser.add_argument("--url", type=str, required=True, help="The .ics file to read/write")
	subparsers = parser.add_subparsers(help="Commands", dest="subcommand")

	query = subparsers.add_parser("query")
	query.add_argument("startTime", type=argparse_date, help="Inclusive starting date in YYYY-MM-DD format")
	query.add_argument("endTime", type=argparse_date, help="Inclusive ending date in YYYY-MM-DD format")

	subparsers.add_parser("add")
	subparsers.add_parser("delete")

	if debugging:
		args = parser.parse_args(["--url", "basic.ics", "query", "2016-09-15", "2016-09-16"])
	else:
		args = parser.parse_args()

	manager = CalendarManager(args.url)
	if args.subcommand == "query":
		manager.read()
		event_list = manager.query(args.startTime, args.endTime)
		print(events_to_json(event_list))
