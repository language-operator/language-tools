# Web Tool Makefile
# This Makefile uses the shared tools.mk for common targets

# Image configuration
IMAGE_NAME := ghcr.io/language-operator/web-tool
TOOL_NAME := web

# Include shared targets
include ../tools.mk

# Web-specific test target
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
	@echo ""
	@echo "Testing web_status for 'https://example.com'..."
	@curl -s -X POST http://localhost:8080/mcp \
		-H "Content-Type: application/json" \
		-d '{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"web_status","arguments":{"url":"https://example.com"}}}' | jq -r '.result.content[0].text'
	@echo ""
	@echo "Testing web_headers for 'https://example.com'..."
	@curl -s -X POST http://localhost:8080/mcp \
		-H "Content-Type: application/json" \
		-d '{"jsonrpc":"2.0","id":4,"method":"tools/call","params":{"name":"web_headers","arguments":{"url":"https://example.com"}}}' | jq -r '.result.content[0].text' | head -10
	@echo ""
	@echo "Testing web_fetch for 'https://example.com'..."
	@curl -s -X POST http://localhost:8080/mcp \
		-H "Content-Type: application/json" \
		-d '{"jsonrpc":"2.0","id":5,"method":"tools/call","params":{"name":"web_fetch","arguments":{"url":"https://example.com","html":false}}}' | jq -r '.result.content[0].text' | head -15
	@echo ""
	@echo "Testing web_search for 'ruby programming'..."
	@curl -s -X POST http://localhost:8080/mcp \
		-H "Content-Type: application/json" \
		-d '{"jsonrpc":"2.0","id":6,"method":"tools/call","params":{"name":"web_search","arguments":{"query":"ruby programming","max_results":3}}}' | jq -r '.result.content[0].text' | head -20
