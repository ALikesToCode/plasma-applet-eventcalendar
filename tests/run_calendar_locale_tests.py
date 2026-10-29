#!/usr/bin/env python3
"""Run the production calendar path and extracted display expressions in Qt 6.

Requires qmltestrunner, QtQuick, QtQml.Models, QtQml.WorkerScript, and QtTest.
No Plasma session, Google account, network access, or stored credentials are used.
"""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile


TESTS = Path(__file__).resolve().parent


def label_expression(source: str, item_id: str) -> str:
    match = re.search(r"\bid:\s*" + re.escape(item_id) + r"\b(?:(?!\bid:)[\s\S])*?\btext:\s*([^\n]+)", source)
    if match is None:
        raise ValueError(f"Cannot find the text binding for {item_id}")
    return match[1].strip()


def translated_format(source_root: Path, locale: str, context: str, fallback: str) -> str:
    language = "ru" if locale.startswith("ru") else "de" if locale.startswith("de") else None
    if language is None:
        return fallback
    catalog = (source_root / "package/translate" / f"{language}.po").read_text()
    match = re.search(
        r'msgctxt ' + re.escape(json.dumps(context)) + r'\s+msgid "[^"\n]*"\s+msgstr ("[^"\n]*")',
        catalog,
    )
    return json.loads(match[1]) if match and json.loads(match[1]) else fallback


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source-root", type=Path, default=TESTS.parent,
                        help="Checkout to test; supports running the same tests before and after a change")
    parser.add_argument("--locale", action="append", choices=["de_DE", "en_US", "ru_RU"],
                        help="Repeat to test multiple locales; defaults to all three")
    parser.add_argument("--qmltestrunner", default=os.environ.get("QMLTESTRUNNER"))
    args = parser.parse_args()
    source_root = args.source_root.resolve()
    runner = args.qmltestrunner or shutil.which("qmltestrunner6")
    if runner is None and Path("/usr/lib/qt6/bin/qmltestrunner").is_file():
        runner = "/usr/lib/qt6/bin/qmltestrunner"
    runner = runner or shutil.which("qmltestrunner")
    if runner is None:
        parser.error("Qt 6 qmltestrunner is required; set QMLTESTRUNNER or --qmltestrunner")

    agenda = (source_root / "package/contents/ui/AgendaListItem.qml").read_text()
    clock = (source_root / "package/contents/ui/ClockView.qml").read_text()
    full_date = re.search(r"function fullDateLabel\(\)\s*\{([\s\S]*?)\n\s*\}", agenda)
    if full_date is None:
        raise ValueError("Cannot find fullDateLabel")
    template = (TESTS / "tst_calendar_locale.qml").read_text()
    template = template.replace('"../package/contents/ui"', json.dumps((source_root / "package/contents/ui").as_uri()))
    template = template.replace('"../package/contents/ui/calendars"', json.dumps((source_root / "package/contents/ui/calendars").as_uri()))
    fixture = json.loads((TESTS / "fixtures/google_calendar_locale.json").read_text())
    result = 0
    with tempfile.TemporaryDirectory(prefix="eventcalendar-locale-") as directory:
        test_dir = Path(directory)
        (test_dir / "tst_calendar_locale.qml").write_text(template)
        for locale in args.locale or ["de_DE", "en_US", "ru_RU"]:
            bindings = {
                "localeName": locale,
                "dateExpression": label_expression(agenda, "itemDate"),
                "dayExpression": label_expression(agenda, "itemDay"),
                "clockExpressions": [label_expression(clock, "timeLabel1"), label_expression(clock, "timeLabel2")],
                "fullDateBody": full_date[1],
                "dateFormat": translated_format(source_root, locale, "agenda date format line 1", "MMM d"),
                "dayFormat": translated_format(source_root, locale, "agenda date format line 2", "ddd"),
                "response": fixture,
            }
            (test_dir / "CalendarLocaleBindings.js").write_text(
                ".pragma library\nvar data = " + json.dumps(bindings, ensure_ascii=False) + "\n"
            )
            environment = os.environ.copy()
            environment.update(LANG=f"{locale}.UTF-8", LC_ALL=f"{locale}.UTF-8", TZ="Europe/Berlin",
                               QT_QPA_PLATFORM="offscreen", QT_QUICK_BACKEND="software", QML_DISABLE_DISK_CACHE="1")
            print(f"Testing {source_root} with Qt locale {locale}, timezone Europe/Berlin", flush=True)
            completed = subprocess.run([runner, "-input", str(test_dir / "tst_calendar_locale.qml")],
                                       env=environment, check=False)
            result = result or completed.returncode
    return result


if __name__ == "__main__":
    raise SystemExit(main())
