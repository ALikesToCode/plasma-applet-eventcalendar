import argparse
import contextlib
import importlib.util
import io
import json
import pathlib
import threading
import unittest
import urllib.request


ROOT = pathlib.Path(__file__).resolve().parents[1]
SECRET_STORE_PATH = ROOT / "package" / "contents" / "scripts" / "secret_store.py"


def load_secret_store():
    spec = importlib.util.spec_from_file_location("secret_store", SECRET_STORE_PATH)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class SecretStoreTests(unittest.TestCase):
    def setUp(self):
        self.secret_store = load_secret_store()

    def test_read_command_does_not_write_secret_to_stdout(self):
        self.secret_store.lookup_secret = lambda attributes: (True, "stored-refresh-token")
        args = argparse.Namespace(scope="google-account", key="refresh_token", account_id="acc_1")

        stdout = io.StringIO()
        stderr = io.StringIO()
        with contextlib.redirect_stdout(stdout), contextlib.redirect_stderr(stderr):
            result = self.secret_store.run_read(args)

        self.assertNotEqual(result, 0)
        self.assertEqual(stdout.getvalue(), "")
        self.assertNotIn("stored-refresh-token", stderr.getvalue())

    def test_read_once_requires_authorization_and_returns_secret_as_json(self):
        self.secret_store.lookup_secret = lambda attributes: (True, "stored-refresh-token")
        server = self.secret_store.ReadOnceServer(
            ("127.0.0.1", 0),
            self.secret_store.ReadOnceHandler,
            attributes=[("app", "test")],
            secret_token="test-token",
        )
        server.timeout = 2

        thread = threading.Thread(target=server.handle_request)
        thread.start()
        try:
            request = urllib.request.Request(
                "http://127.0.0.1:{}/read".format(server.server_address[1]),
                headers={"Authorization": "Bearer test-token"},
            )
            with urllib.request.urlopen(request, timeout=2) as response:
                payload = json.loads(response.read().decode("utf-8"))
        finally:
            thread.join(timeout=2)
            server.server_close()

        self.assertEqual(payload, {"found": True, "value": "stored-refresh-token"})
        self.assertTrue(server.shutdown_requested)
        self.assertEqual(server.result, 0)


if __name__ == "__main__":
    unittest.main()
