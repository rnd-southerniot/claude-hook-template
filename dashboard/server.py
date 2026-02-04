#!/usr/bin/env python3
"""
Claude Code Dashboard Server

A simple HTTP server that serves the dashboard and provides API access to log files.
Bypasses browser CORS restrictions for local file access.

Usage:
    python server.py [logs_path] [port]

    logs_path: Path to your project's logs/ directory (default: ../logs)
    port: Port to run server on (default: 8080)

Examples:
    python server.py                                    # Use default ../logs on port 8080
    python server.py /path/to/project/logs             # Custom logs path
    python server.py /path/to/project/logs 3000        # Custom path and port
"""

import http.server
import json
import os
import sys
from pathlib import Path
from urllib.parse import urlparse, parse_qs
import socketserver

# Configuration
DEFAULT_PORT = 8080
DEFAULT_LOGS_PATH = "../logs"


class DashboardHandler(http.server.SimpleHTTPRequestHandler):
    """HTTP handler with API endpoints for log files."""

    logs_path = DEFAULT_LOGS_PATH

    def do_GET(self):
        parsed = urlparse(self.path)
        path = parsed.path

        # API endpoint for logs
        if path.startswith("/api/logs/"):
            self.handle_log_request(path[10:])  # Remove "/api/logs/"
            return

        # API endpoint for all logs
        if path == "/api/logs":
            self.handle_all_logs()
            return

        # API endpoint for config
        if path == "/api/config":
            self.handle_config()
            return

        # Serve static files
        super().do_GET()

    def handle_log_request(self, filename):
        """Serve a specific log file."""
        log_file = Path(self.logs_path) / filename

        if not log_file.exists():
            self.send_error(404, f"Log file not found: {filename}")
            return

        try:
            with open(log_file, "r") as f:
                data = json.load(f)

            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Access-Control-Allow-Origin", "*")
            self.send_header("Cache-Control", "no-cache")
            self.end_headers()
            self.wfile.write(json.dumps(data).encode())
        except json.JSONDecodeError:
            self.send_error(500, f"Invalid JSON in {filename}")
        except Exception as e:
            self.send_error(500, str(e))

    def handle_all_logs(self):
        """Return all available log files and their contents."""
        logs_dir = Path(self.logs_path)

        if not logs_dir.exists():
            self.send_error(404, f"Logs directory not found: {self.logs_path}")
            return

        all_logs = {}
        for log_file in logs_dir.glob("*.json"):
            if log_file.name == ".gitkeep":
                continue
            try:
                with open(log_file, "r") as f:
                    all_logs[log_file.stem] = json.load(f)
            except (json.JSONDecodeError, Exception):
                all_logs[log_file.stem] = []

        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Cache-Control", "no-cache")
        self.end_headers()
        self.wfile.write(json.dumps(all_logs).encode())

    def handle_config(self):
        """Return server configuration."""
        config = {
            "logs_path": str(Path(self.logs_path).absolute()),
            "available_logs": [],
        }

        logs_dir = Path(self.logs_path)
        if logs_dir.exists():
            config["available_logs"] = [
                f.name for f in logs_dir.glob("*.json") if f.name != ".gitkeep"
            ]

        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        self.wfile.write(json.dumps(config).encode())

    def log_message(self, format, *args):
        """Custom logging format."""
        if "/api/" in args[0]:
            print(f"[API] {args[0]}")
        elif args[0].startswith("GET /"):
            # Only log non-polling requests
            if "?" not in args[0]:
                print(f"[Static] {args[0]}")


def main():
    # Parse arguments
    logs_path = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_LOGS_PATH
    port = int(sys.argv[2]) if len(sys.argv) > 2 else DEFAULT_PORT

    # Resolve logs path
    logs_path = str(Path(logs_path).absolute())
    DashboardHandler.logs_path = logs_path

    # Change to dashboard directory
    dashboard_dir = Path(__file__).parent
    os.chdir(dashboard_dir)

    # Start server
    with socketserver.TCPServer(("", port), DashboardHandler) as httpd:
        print(f"""
╔═══════════════════════════════════════════════════════════════╗
║           Claude Code Dashboard Server                         ║
╚═══════════════════════════════════════════════════════════════╝

  Dashboard:  http://localhost:{port}
  Logs Path:  {logs_path}

  API Endpoints:
    GET /api/logs          - All log files
    GET /api/logs/<file>   - Specific log file
    GET /api/config        - Server configuration

  Press Ctrl+C to stop
""")
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\nShutting down...")


if __name__ == "__main__":
    main()
