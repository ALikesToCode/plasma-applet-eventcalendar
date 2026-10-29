# Calendar locale regression investigation

The missing Google agenda reported after PR #50 has not been reproduced by
these tests. The tests cover production calendar fetch orchestration, token
checks, pagination, date parsing, and agenda population. They also evaluate the
checked-out agenda and clock label expressions in Qt, with real ListModel date
roles and small QtQuick delegates. They do not load the complete Plasma widget,
perform a live Google sign-in, or reproduce the reporter's installation.
EventModel/Logic signal wiring is not instantiated: the test hands the
manager's output to AgendaModel directly. Full Plasma component construction
and layout remain outside this harness.

## Run

Install Qt 6 `qmltestrunner` and the QtQuick, QtQml.Models,
QtQml.WorkerScript, and QtTest QML modules. Make the `de_DE.UTF-8`,
`en_US.UTF-8`, and `ru_RU.UTF-8` system locales available, then run:

```bash
python3 tests/run_calendar_locale_tests.py
```

If the tool has a distribution-specific name or location:

```bash
python3 tests/run_calendar_locale_tests.py --qmltestrunner /usr/lib/qt6/bin/qmltestrunner
```

The runner sets `TZ=Europe/Berlin` and starts a separate Qt process for each
locale. `--locale de_DE` selects just German. `--source-root /path/to/checkout`
tests a different revision using the same fixtures and assertions. Google
responses and account persistence are synthetic; the tests use no real tokens,
calendar data, or network requests. Catalog date-format strings and display
expressions are read from the selected checkout, rather than reimplemented.

## Coverage and interpretation

Seven Google-format events cover an ordinary timed appointment, an all-day
event, a three-day event, a recurring-event instance, a UTC-midnight boundary,
and the two distinct occurrences of 02:30 on October 25, 2026. Two response
pages exercise aggregation before events reach the production AgendaModel.
The tests assert event counts, local dates and times, displayed summaries,
localized date and weekday labels, both clock label expressions, expiry-driven
token refresh, reauthorization failure, and an intentionally empty calendar
selection.

Before PR #50 (`a00afab4`), the German localization assertion fails because the
agenda displays `28 Oct` instead of `28 Okt.`. Fetching, parsing, and event
population still pass. After PR #50 (`db7abff2`), that localization check passes
alongside the event-path checks. This establishes a useful comparison; it does
not rule out a failure specific to another Qt/Plasma version or saved account.

The six behavioral cases pass in each of the three locales on Qt 6.4.2, 6.8.2,
and 6.10.2. The existing 21 Node checks and 10 Python checks also pass; the
Python run uses `icalendar` 7.3.0 and `recurring-ical-events` 3.8.2. With the
older Ubuntu packages (`icalendar` 5.0.11 and `recurring-ical-events` 2.1.2), the
existing `test_recurring_events_apply_exdates_and_overrides` fails its event
ordering assertion. That dependency-related failure predates these additions
and is separate from the Google Calendar path.

The query path serializes range boundaries with `toISOString()` in
`GoogleCalendarManager.qml`. `CalendarManager.qml` parses Google dateTime
strings and all-day date strings before `AgendaModel.qml` groups events.
The two files changed by PR #50 format presentation values downstream of that
path.

Existing reports reviewed include #23, #30, #31, #33, and #44, and PRs #27,
#37/#38, #39, #41, #45, #49, and #50. Earlier reports establish that Google
authentication and disappearing events predate the locale change; they do not
establish the cause of this report. Further diagnosis needs the installation
details and redacted error output already requested in the existing email
conversation. No production correction is included without a matching
reproduction.
