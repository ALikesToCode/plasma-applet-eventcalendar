"""Script to handle oauth redirects from Google"""

import json
import urllib.parse
import urllib.request
import urllib.error
import argparse
import sys
from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import urlparse, parse_qs

client_id = client_secret = listen_port = redirect_uri = expected_state = None


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
    def do_GET(self):
        query = urlparse(self.path).query
        params = parse_qs(query)
        code = params.get("code", [""])[0]
        state = params.get("state", [""])[0]

        if not code:
            self.send_response(400)
            self.send_header("Content-type", "text/plain")
            self.end_headers()
            self.wfile.write(b"Missing code parameter in redirect.")
            raise SystemExit(1)

        if expected_state and state != expected_state:
            print("State mismatch in OAuth redirect.", file=sys.stderr)
            sys.stderr.flush()
            self.send_response(400)
            self.send_header("Content-type", "text/plain")
            self.end_headers()
            self.wfile.write(b"State mismatch in redirect. Please retry the login.")
            raise SystemExit(1)

        try:
            token_data = exchange_code_for_token(code)
        except urllib.error.HTTPError as e:
            print(e.read().decode("utf-8"))
            self.send_response(400)
            self.send_header("Content-type", "text/plain")
            self.end_headers()
            self.wfile.write(b"Handling redirect failed.")
            raise SystemExit(1)

        print(json.dumps(token_data, sort_keys=True))

        self.send_response(200)
        self.send_header("Content-type", "text/html")
        self.end_headers()
        self.wfile.write(
            b"OAuth redirect handled successfully. You can close this tab now."
        )
        raise SystemExit(0)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--client_id", required=True)
    parser.add_argument("--client_secret", required=True)
    parser.add_argument("--listen_port", required=True, type=int)
    parser.add_argument("--state", default="")
    args = parser.parse_args()
    client_id = args.client_id
    client_secret = args.client_secret
    listen_port = args.listen_port
    redirect_uri = "http://127.0.0.1:{}/".format(listen_port)
    expected_state = args.state

    server_address = ("127.0.0.1", listen_port)
    httpd = HTTPServer(server_address, OAuthRedirectHandler)
    httpd.serve_forever()
