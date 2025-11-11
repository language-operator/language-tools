# MCP Tool Makefile
# This Makefile uses the shared tools.mk for common targets

# Image configuration
IMAGE_NAME := ghcr.io/language-operator/mcp-tool
TOOL_NAME := mcp

# Include shared targets
include ../tools.mk

# MCP-specific test target
.PHONY: test
test:
	@echo "Testing health endpoint..."
	@curl -s http://localhost:8080/health | jq .
	@echo ""
	@echo "Initializing MCP session..."
	@curl -s -X POST http://localhost:8080/mcp \
		-H "Content-Type: application/json" \
		-d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}}' | jq '.result.serverInfo'
	@echo ""
	@echo "Listing available tools via MCP..."
	@curl -s -X POST http://localhost:8080/mcp \
		-H "Content-Type: application/json" \
		-d '{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}' | jq '.result.tools[] | {name, description}'
