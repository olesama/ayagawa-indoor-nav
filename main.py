from http.server import ThreadingHTTPServer, SimpleHTTPRequestHandler
import os

PORT = int(os.environ.get("PORT", "3000"))

class Handler(SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header("Cache-Control", "no-cache")
        super().end_headers()

if __name__ == "__main__":
    print(f"綾川イオン館内ナビを起動します: http://0.0.0.0:{PORT}")
    server = ThreadingHTTPServer(("0.0.0.0", PORT), Handler)
    server.serve_forever()
