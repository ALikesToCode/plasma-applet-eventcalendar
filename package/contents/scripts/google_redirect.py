"""Script to handle oauth redirects from Google"""

import json
import urllib.parse
import urllib.request
import urllib.error
import argparse
import sys
import threading
from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import urlparse, parse_qs

client_id = client_secret = listen_port = redirect_uri = None
exit_code = 0


def exchange_code_for_token(code):
    # Exchange code for token from https://oauth2.googleapis.com/token
    # using the following POST request:
    token_params = {
        "code": code,
        "client_id": client_id,
        "client_secret": client_secret,
        "redirect_uri": redirect_uri,
        "grant_type": "authorization_code",
    }
    data = urllib.parse.urlencode(token_params).encode("utf-8")
    req = urllib.request.Request("https://oauth2.googleapis.com/token", data)
    response = urllib.request.urlopen(req)
    token_data = json.loads(response.read().decode("utf-8"))
    return token_data


class OAuthRedirectHandler(BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        return

    def _send_headers(self, status, content_type):
        self.send_response(status)
        self.send_header("Content-type", content_type)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "POST, OPTIONS, GET")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.send_header("Access-Control-Allow-Private-Network", "true")
        self.end_headers()

    def _shutdown(self):
        threading.Thread(target=self.server.shutdown, daemon=True).start()

    def _set_exit_code(self, code):
        global exit_code
        exit_code = code

    def _extract_code(self, value):
        if not value:
            return ""
        text = value.strip()
        parsed = urlparse(text)
        if parsed.query:
            params = parse_qs(parsed.query)
            if "code" in params:
                return params["code"][0]
        if "code=" in text:
            params = parse_qs(text.split("?", 1)[-1])
            if "code" in params:
                return params["code"][0]
        return text

    def _handle_code(self, code, html_response):
        if not code:
            self._send_headers(400, "text/plain")
            self.wfile.write(b"Missing code parameter in redirect.")
            return
        try:
            token_data = exchange_code_for_token(code)
        except urllib.error.HTTPError as e:
            print(e.read().decode("utf-8"))
            sys.stdout.flush()
            self._set_exit_code(1)
            self._send_headers(400, "text/plain")
            self.wfile.write(b"Handling redirect failed.")
            self._shutdown()
            return
        except urllib.error.URLError as e:
            print(str(e))
            sys.stdout.flush()
            self._set_exit_code(1)
            self._send_headers(400, "text/plain")
            self.wfile.write(b"Handling redirect failed.")
            self._shutdown()
            return

        print(json.dumps(token_data, sort_keys=True))
        sys.stdout.flush()
        self._set_exit_code(0)
        if html_response:
            self._send_headers(200, "text/html")
            self.wfile.write(
                b"OAuth redirect handled successfully. You can close this tab now."
            )
        else:
            self._send_headers(200, "text/plain")
            self.wfile.write(b"OK")
        self._shutdown()

    def do_OPTIONS(self):
        self._send_headers(204, "text/plain")

    def do_GET(self):
        query = urlparse(self.path).query
        params = parse_qs(query)
        code = params.get("code", [""])[0]
        self._handle_code(self._extract_code(code), html_response=True)

    def do_POST(self):
        content_length = int(self.headers.get("Content-Length", 0))
        raw_body = self.rfile.read(content_length).decode("utf-8") if content_length else ""
        content_type = self.headers.get("Content-Type", "")
        code = ""
        if "application/json" in content_type:
            try:
                payload = json.loads(raw_body) if raw_body else {}
                code = payload.get("code", "")
            except json.JSONDecodeError:
                code = ""
        else:
            params = parse_qs(raw_body)
            code = params.get("code", [""])[0]
        self._handle_code(self._extract_code(code), html_response=False)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--client_id", required=True)
    parser.add_argument("--client_secret", required=True)
    parser.add_argument("--listen_port", required=True, type=int)
    parser.add_argument("--redirect_uri", default="")
    args = parser.parse_args()
    client_id = args.client_id
    client_secret = args.client_secret
    listen_port = args.listen_port
    redirect_uri = args.redirect_uri or "http://127.0.0.1:{}/".format(listen_port)

    server_address = ("", listen_port)
    httpd = HTTPServer(server_address, OAuthRedirectHandler)
    httpd.serve_forever()
    sys.exit(exit_code)
