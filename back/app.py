import signal
import sys
from http.server import BaseHTTPRequestHandler, HTTPServer


class SRV(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/health":
            self.send_response(200)
            self.send_header("Content-type", "text/plain; charset=utf-8")
            self.end_headers()
            self.wfile.write(b"ok\n")
            return

        self.send_response(200)
        self.send_header("Content-type", "text/plain; charset=utf-8")
        self.end_headers()
        self.wfile.write(b"Hello from Effective Mobile!\n")


server = HTTPServer(("0.0.0.0", 8080), SRV)


def shutdown(signum, frame):
    server.shutdown()
    sys.exit(0)


signal.signal(signal.SIGTERM, shutdown)
signal.signal(signal.SIGINT, shutdown)
server.serve_forever()
