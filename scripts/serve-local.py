"""Serve the saved Flutter web build on localhost, with browser caching off."""
from argparse import ArgumentParser
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path


class LocalBuildHandler(SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Cache-Control', 'no-store')
        super().end_headers()


def main():
    parser = ArgumentParser(description=__doc__)
    parser.add_argument('--port', type=int, default=8080)
    options = parser.parse_args()
    build = Path(__file__).resolve().parents[1] / 'build' / 'web'
    if not (build / 'index.html').is_file():
        parser.error('Jalankan flutter build web --release terlebih dahulu.')
    server = ThreadingHTTPServer(('127.0.0.1', options.port),
                                 partial(LocalBuildHandler, directory=str(build)))
    print(f'MoneyWork: http://localhost:{server.server_port}/', flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()


if __name__ == '__main__':
    main()
