#!/usr/bin/env python3
"""
HTTP to STDIO bridge for MCP servers.
Accepts HTTP requests and proxies them to a stdio-based MCP server.
"""
import asyncio
import json
import subprocess
import sys
from typing import Dict, Any, Optional
from aiohttp import web, web_request
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class MCPStdioBridge:
    def __init__(self, command: list[str]):
        self.command = command
        self.process: Optional[subprocess.Popen] = None
        
    async def start_process(self):
        """Start the MCP server process."""
        logger.info(f"Starting MCP server: {' '.join(self.command)}")
        self.process = subprocess.Popen(
            self.command,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            bufsize=0
        )
        
    async def send_request(self, request: Dict[str, Any]) -> Dict[str, Any]:
        """Send a request to the MCP server and get response."""
        if not self.process:
            await self.start_process()
            
        try:
            # Send request
            request_json = json.dumps(request) + '\n'
            logger.info(f"Sending to MCP server: {request_json.strip()}")
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
            if self.process:
                self.process.terminate()
                self.process = None
            raise

async def handle_mcp_request(request: web_request.Request) -> web.Response:
    """Handle MCP HTTP requests."""
    try:
        body = await request.json()
        logger.info(f"Received HTTP request: {body}")
        
        # Get the bridge from app state
        bridge = request.app['bridge']
        
        # Forward to MCP server
        response = await bridge.send_request(body)
        
        return web.json_response(response)
        
    except Exception as e:
        logger.error(f"Error handling request: {e}")
        return web.json_response({
            "jsonrpc": "2.0",
            "id": body.get("id") if 'body' in locals() else None,
            "error": {
                "code": -32603,
                "message": f"Internal error: {str(e)}"
            }
        }, status=500)

async def handle_health(request: web_request.Request) -> web.Response:
    """Health check endpoint."""
    return web.json_response({"status": "ok", "service": "mcp-stdio-bridge"})

def create_app(command: list[str]) -> web.Application:
    """Create the web application."""
    app = web.Application()
    app['bridge'] = MCPStdioBridge(command)
    
    # Routes
    app.router.add_post('/mcp', handle_mcp_request)
    app.router.add_get('/health', handle_health)
    
    return app

if __name__ == "__main__":
    # Command to run the MCP server
    mcp_command = ["mcp-server-time"]
    if len(sys.argv) > 1:
        mcp_command.extend(sys.argv[1:])
    
    app = create_app(mcp_command)
    
    # Run on port 80
    web.run_app(app, host='0.0.0.0', port=80)