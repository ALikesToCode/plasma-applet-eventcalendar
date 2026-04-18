"""Execute a non-secret argv payload without shell parsing."""

from __future__ import annotations

import argparse
import base64
import json
import subprocess
import sys


SENSITIVE_FLAGS = {
    "--access-token",
    "--access_token",
    "--refresh-token",
    "--refresh_token",
    "--client-secret",
    "--client_secret",
    "--password",
    "--passwd",
    "--authorization",
    "--cookie",
}


def decode_argv(payload: str) -> list[str]:
    try:
        decoded = base64.urlsafe_b64decode(payload.encode("ascii")).decode("utf-8")
        parsed = json.loads(decoded)
    except (ValueError, json.JSONDecodeError) as exc:
        raise ValueError("Invalid argv payload: {}".format(exc)) from exc
    if not isinstance(parsed, list) or not parsed:
        raise ValueError("Argv payload must be a non-empty list.")
    argv = []
    for item in parsed:
        if item is None:
            item = ""
        argv.append(str(item))
    return argv


def contains_sensitive_argv(argv: list[str]) -> bool:
    for index, arg in enumerate(argv):
        lowered = arg.lower()
        if lowered in SENSITIVE_FLAGS:
            return True
        if index > 0 and argv[index - 1].lower() in SENSITIVE_FLAGS:
            return True
        if lowered.startswith("authorization:") or lowered.startswith("cookie:") or lowered.startswith("bearer "):
            return True
    return False


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("payload")
    args = parser.parse_args()

    try:
        argv = decode_argv(args.payload)
    except ValueError as exc:
        print(str(exc), file=sys.stderr)
        return 1
    if contains_sensitive_argv(argv):
        print("run_argv.py rejects secret-bearing argv payloads; pass secrets via stdin or dedicated IPC.", file=sys.stderr)
        return 1

    proc = subprocess.run(argv, text=True, capture_output=True, check=False)
    if proc.stdout:
        sys.stdout.write(proc.stdout)
    if proc.stderr:
        sys.stderr.write(proc.stderr)
    return proc.returncode


if __name__ == "__main__":
    sys.exit(main())
