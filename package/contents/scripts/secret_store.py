"""Store and retrieve app secrets via Secret Service or KWallet."""

from __future__ import annotations

import argparse
import json
import os
import secrets
import shutil
import subprocess
import sys
import tempfile
import time
from http.server import BaseHTTPRequestHandler, HTTPServer


APP_ID = "plasma-applet-eventcalendar"
READY_FILE_MODE = 0o600
DEFAULT_TIMEOUT = 30
KWALLET_FOLDER = "plasma-applet-eventcalendar"
KWALLET_NAMES = ("kdewallet", "kdewallet5")


def build_attributes(args: argparse.Namespace) -> list[tuple[str, str]]:
    attrs = [
        ("app", APP_ID),
        ("scope", args.scope),
        ("key", args.key),
    ]
    if getattr(args, "account_id", ""):
        attrs.append(("account_id", args.account_id))
    return attrs


def flatten_attributes(attributes: list[tuple[str, str]]) -> list[str]:
    flattened: list[str] = []
    for key, value in attributes:
        flattened.extend([key, value])
    return flattened


def kwallet_entry_name(attributes: list[tuple[str, str]]) -> str:
    parts = []
    for key, value in attributes:
        if value:
            parts.append("{}={}".format(key, value))
    return "|".join(parts)


def secret_tool_path() -> str | None:
    return shutil.which("secret-tool")


def store_with_secret_tool(attributes: list[tuple[str, str]], label: str, value: str) -> bool:
    secret_tool = secret_tool_path()
    if not secret_tool:
        return False
    cmd = [secret_tool, "store", "--label={}".format(label)] + flatten_attributes(attributes)
    proc = subprocess.run(
        cmd,
        input=value,
        text=True,
        capture_output=True,
    )
    return proc.returncode == 0


def lookup_with_secret_tool(attributes: list[tuple[str, str]]) -> tuple[bool, str]:
    secret_tool = secret_tool_path()
    if not secret_tool:
        return False, ""
    cmd = [secret_tool, "lookup"] + flatten_attributes(attributes)
    proc = subprocess.run(cmd, text=True, capture_output=True)
    if proc.returncode != 0:
        return False, ""
    return True, proc.stdout.rstrip("\n")


def clear_with_secret_tool(attributes: list[tuple[str, str]]) -> bool:
    secret_tool = secret_tool_path()
    if not secret_tool:
        return False
    cmd = [secret_tool, "clear"] + flatten_attributes(attributes)
    proc = subprocess.run(cmd, text=True, capture_output=True)
    return proc.returncode == 0


def kwallet_query_path() -> str | None:
    return shutil.which("kwallet-query")


def detect_kwallet_name(kwallet_query: str) -> str | None:
    for wallet_name in KWALLET_NAMES:
        proc = subprocess.run(
            [kwallet_query, "-l", wallet_name],
            text=True,
            capture_output=True,
        )
        if proc.returncode == 0:
            return wallet_name
    return None


def store_with_kwallet(attributes: list[tuple[str, str]], value: str) -> bool:
    kwallet_query = kwallet_query_path()
    if not kwallet_query:
        return False
    wallet_name = detect_kwallet_name(kwallet_query)
    if not wallet_name:
        return False
    cmd = [
        kwallet_query,
        "-f",
        KWALLET_FOLDER,
        "-w",
        kwallet_entry_name(attributes),
        wallet_name,
    ]
    proc = subprocess.run(cmd, input=value, text=True, capture_output=True)
    return proc.returncode == 0


def lookup_with_kwallet(attributes: list[tuple[str, str]]) -> tuple[bool, str]:
    kwallet_query = kwallet_query_path()
    if not kwallet_query:
        return False, ""
    wallet_name = detect_kwallet_name(kwallet_query)
    if not wallet_name:
        return False, ""
    cmd = [
        kwallet_query,
        "-f",
        KWALLET_FOLDER,
        "-r",
        kwallet_entry_name(attributes),
        wallet_name,
    ]
    proc = subprocess.run(cmd, text=True, capture_output=True)
    if proc.returncode != 0:
        return False, ""
    return True, proc.stdout.rstrip("\n")


def clear_with_kwallet(attributes: list[tuple[str, str]]) -> bool:
    kwallet_query = kwallet_query_path()
    if not kwallet_query:
        return False
    wallet_name = detect_kwallet_name(kwallet_query)
    if not wallet_name:
        return False
    cmd = [
        kwallet_query,
        "-f",
        KWALLET_FOLDER,
        "-w",
        kwallet_entry_name(attributes),
        wallet_name,
    ]
    proc = subprocess.run(cmd, input="", text=True, capture_output=True)
    return proc.returncode == 0


def store_secret(attributes: list[tuple[str, str]], label: str, value: str) -> bool:
    return store_with_secret_tool(attributes, label, value) or store_with_kwallet(attributes, value)


def lookup_secret(attributes: list[tuple[str, str]]) -> tuple[bool, str]:
    found, value = lookup_with_secret_tool(attributes)
    if found:
        return True, value
    return lookup_with_kwallet(attributes)


def clear_secret(attributes: list[tuple[str, str]]) -> bool:
    cleared = clear_with_secret_tool(attributes)
    kwallet_cleared = clear_with_kwallet(attributes)
    return cleared or kwallet_cleared


def atomic_write_json(path: str, data: dict) -> None:
    directory = os.path.dirname(path) or "."
    os.makedirs(directory, exist_ok=True)
    fd, tmp_path = tempfile.mkstemp(prefix=".secret-store-", dir=directory)
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as handle:
            json.dump(data, handle)
            handle.flush()
            os.fchmod(handle.fileno(), READY_FILE_MODE)
        os.replace(tmp_path, path)
        os.chmod(path, READY_FILE_MODE)
    finally:
        if os.path.exists(tmp_path):
            os.unlink(tmp_path)


def parse_store_payload(raw_body: str) -> str:
    if not raw_body:
        raise ValueError("Missing request body.")
    payload = json.loads(raw_body)
    value = payload.get("value", "")
    if not isinstance(value, str):
        raise ValueError("Secret value must be a string.")
    return value


class StoreOnceHandler(BaseHTTPRequestHandler):
    server_version = "SecretStore/1.0"

    def log_message(self, format: str, *args) -> None:
        return

    def _send_json(self, status: int, payload: dict) -> None:
        body = json.dumps(payload).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_POST(self) -> None:
        if self.path != "/store":
            self._send_json(404, {"error": "Not found."})
            return
        expected_auth = "Bearer " + self.server.secret_token
        if self.headers.get("Authorization", "") != expected_auth:
            self._send_json(403, {"error": "Forbidden."})
            return
        try:
            content_length = int(self.headers.get("Content-Length", "0"))
        except ValueError:
            content_length = 0
        raw_body = self.rfile.read(content_length).decode("utf-8") if content_length else ""
        try:
            value = parse_store_payload(raw_body)
        except (json.JSONDecodeError, ValueError) as exc:
            self._send_json(400, {"error": str(exc)})
            return
        ok = store_secret(self.server.attributes, self.server.label, value)
        if not ok:
            self._send_json(500, {"error": "Secret storage backend unavailable."})
            self.server.result = 1
        else:
            self._send_json(200, {"ok": True})
            self.server.result = 0
        self.server.shutdown_requested = True
        self.server.shutdown()


class StoreOnceServer(HTTPServer):
    def __init__(self, server_address, request_handler_class, *, attributes, label, secret_token):
        super().__init__(server_address, request_handler_class)
        self.attributes = attributes
        self.label = label
        self.secret_token = secret_token
        self.result = 1
        self.shutdown_requested = False


def run_read(args: argparse.Namespace) -> int:
    found, value = lookup_secret(build_attributes(args))
    if not found:
        print("")
        return 1
    print(value)
    return 0


def run_clear(args: argparse.Namespace) -> int:
    ok = clear_secret(build_attributes(args))
    return 0 if ok else 1


def run_store_once(args: argparse.Namespace) -> int:
    attributes = build_attributes(args)
    label = "{} {} {}".format(APP_ID, args.scope, args.key)
    token = secrets.token_urlsafe(24)
    server = StoreOnceServer(("127.0.0.1", 0), StoreOnceHandler, attributes=attributes, label=label, secret_token=token)
    ready_payload = {
        "port": server.server_address[1],
        "token": token,
    }
    atomic_write_json(args.ready_file, ready_payload)
    deadline = time.monotonic() + args.timeout
    server.timeout = 1
    try:
        while not server.shutdown_requested and time.monotonic() < deadline:
            server.handle_request()
    finally:
        server.server_close()
        try:
            os.unlink(args.ready_file)
        except OSError:
            pass
    if not server.shutdown_requested:
        return 1
    return server.result


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(dest="command", required=True)

    def add_shared_arguments(cmd: argparse.ArgumentParser, include_account_id: bool = True) -> None:
        cmd.add_argument("--scope", required=True)
        cmd.add_argument("--key", required=True)
        if include_account_id:
            cmd.add_argument("--account-id", default="")

    read_cmd = subparsers.add_parser("read")
    add_shared_arguments(read_cmd)

    clear_cmd = subparsers.add_parser("clear")
    add_shared_arguments(clear_cmd)

    store_once_cmd = subparsers.add_parser("store-once")
    add_shared_arguments(store_once_cmd)
    store_once_cmd.add_argument("--ready-file", required=True)
    store_once_cmd.add_argument("--timeout", type=int, default=DEFAULT_TIMEOUT)

    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()
    if args.command == "read":
        return run_read(args)
    if args.command == "clear":
        return run_clear(args)
    if args.command == "store-once":
        return run_store_once(args)
    parser.error("Unknown command.")
    return 1


if __name__ == "__main__":
    sys.exit(main())
