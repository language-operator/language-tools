#!/usr/bin/env python3
"""
HTTP to STDIO bridge for MCP servers using built-in http.server.
Accepts HTTP requests and proxies them to a stdio-based MCP server.
"""
import json
import subprocess
import sys
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse
import logging
import threading
import time

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class MCPStdioBridge:
    def __init__(self, command):
        self.command = command
        self.process = None
        self.lock = threading.Lock()
        
    def start_process(self):
        """Start the MCP server process."""
        with self.lock:
            if self.process is None:
                logger.info(f"Starting MCP server: {' '.join(self.command)}")
                self.process = subprocess.Popen(
                    self.command,
                    stdin=subprocess.PIPE,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE,
                    text=True,
                    bufsize=1
                )
        
    def send_request(self, request):
        """Send a request to the MCP server and get response."""
        if not self.process:
            self.start_process()
            
        try:
            # Send request
            request_json = json.dumps(request) + '\n'
            logger.info(f"Sending to MCP server: {request_json.strip()}")
            
            with self.lock:
                self.process.stdin.write(request_json)
                self.process.stdin.flush()
                
                # Read response
                response_line = self.process.stdout.readline()
                logger.info(f"Received from MCP server: {response_line.strip()}")
                
                if not response_line:
                    raise Exception("No response from MCP server")
                    
                return json.loads(response_line)
                
        except Exception as e:
            logger.error(f"Error communicating with MCP server: {e}")
            with self.lock:
                if self.process:
                    self.process.terminate()
                    self.process = None
            raise

# Global bridge instance
bridge = None

class MCPHandler(BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        # Override to use our logger
        logger.info(f"{self.address_string()} - {format % args}")
        
    def do_POST(self):
        """Handle POST requests to /mcp endpoint."""
        if self.path != '/mcp':
            self.send_error(404, "Not Found")
            return
            
        try:
            content_length = int(self.headers['Content-Length'])
            body = self.rfile.read(content_length).decode('utf-8')
            request_data = json.loads(body)
            
            logger.info(f"Received HTTP request: {request_data}")
            
            # Forward to MCP server
            response = bridge.send_request(request_data)
            
            # Send response
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            
            response_json = json.dumps(response)
            self.wfile.write(response_json.encode('utf-8'))
            
        except Exception as e:
            logger.error(f"Error handling request: {e}")
            self.send_response(500)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            
            error_response = {
                "jsonrpc": "2.0",
                "id": request_data.get("id") if 'request_data' in locals() else None,
                "error": {
                    "code": -32603,
                    "message": f"Internal error: {str(e)}"
                }
            }
            self.wfile.write(json.dumps(error_response).encode('utf-8'))

    def do_GET(self):
        """Handle GET requests for health check."""
        if self.path == '/health':
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            
            health_response = {"status": "ok", "service": "mcp-stdio-bridge"}
            self.wfile.write(json.dumps(health_response).encode('utf-8'))
        else:
            self.send_error(404, "Not Found")

if __name__ == "__main__":
    # Command to run the MCP server  
    mcp_command = ["python", "-m", "shell_mcp_server"]
    if len(sys.argv) > 1:
        mcp_command.extend(sys.argv[1:])
    
    # Create bridge
    bridge = MCPStdioBridge(mcp_command)
    
    # Start HTTP server
    server = HTTPServer(('0.0.0.0', 80), MCPHandler)
    logger.info("HTTP-to-stdio bridge starting on port 80")
    
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        logger.info("Shutting down...")
        if bridge.process:
            bridge.process.terminate()
        server.shutdown()