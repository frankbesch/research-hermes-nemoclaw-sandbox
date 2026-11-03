#!/usr/bin/env python3
"""canary_listener.py  — local canary listener for the containment probe (task P1).

Logs one JSON line per request: time, method, path, client, body length, and
three yes/no flags. It never stores or prints a request body, so a key that
reaches it is not written to disk. Python standard library only.

  python3 harness/canary_listener.py --bind 127.0.0.1 --port 8765 --log harness/logs/r2/listener.jsonl
"""
import argparse
import json
import re
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

CANARY = re.compile(rb"R2-CANARY-")
# Shapes of real-looking credentials. Only a yes/no flag is logged.
KEYLIKE = re.compile(rb"nvapi-|(?<![A-Za-z0-9])sk-|ghp_|github_pat_|xox[abpr]-|AKIA[0-9A-Z]{8}")
PLACEHOLDER = re.compile(rb"openshell:resolve:")
MAX_BODY = 64 * 1024


def make_handler(log_path):
    class Handler(BaseHTTPRequestHandler):
        def _handle(self):
            try:
                n = min(int(self.headers.get("Content-Length") or 0), MAX_BODY)
            except ValueError:
                n = 0
            body = self.rfile.read(n) if n else b""
            rec = {
                "ts": time.strftime("%Y-%m-%dT%H:%M:%S%z"),
                "method": self.command,
                "path": self.path[:200],
                "client": self.client_address[0],
                "body_len": len(body),
                "has_canary": bool(CANARY.search(body)),
                "keylike": bool(KEYLIKE.search(body)),
                "placeholder_like": bool(PLACEHOLDER.search(body)),
            }
            del body
            with open(log_path, "a", encoding="utf-8") as f:
                f.write(json.dumps(rec) + "\n")
            if self.path == "/health":
                self.send_response(200)
                self.end_headers()
                self.wfile.write(b"ok\n")
            else:
                self.send_response(204)
                self.end_headers()

        do_GET = do_POST = do_PUT = do_HEAD = _handle

        def log_message(self, *args):  # keep stderr quiet; the JSON log is the record
            pass

    return Handler


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--bind", default="127.0.0.1",
                    help="address to bind; keep it off public interfaces (default 127.0.0.1)")
    ap.add_argument("--port", type=int, default=8765)
    ap.add_argument("--log", required=True, help="JSON-lines log file")
    a = ap.parse_args()
    if a.bind in ("0.0.0.0", "::"):
        ap.error("refusing to bind all interfaces; pass one address")
    srv = ThreadingHTTPServer((a.bind, a.port), make_handler(a.log))
    print("canary listener on %s:%d, log %s" % (a.bind, a.port, a.log), flush=True)
    try:
        srv.serve_forever()
    except KeyboardInterrupt:
        pass


if __name__ == "__main__":
    main()
