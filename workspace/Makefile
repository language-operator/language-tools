# Workspace Tool Makefile
# This Makefile uses the shared tools.mk for common targets

# Image configuration
IMAGE_NAME := git.theryans.io/language-operator/workspace-tool
TOOL_NAME := workspace

# Include shared targets
include ../tools.mk

# Workspace-specific test target
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
	@echo "Testing read_file for '/workspace/README.md'..."
	@curl -s -X POST http://localhost:8080/mcp \
		-H "Content-Type: application/json" \
		-d '{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"read_file","arguments":{"path":"README.md"}}}' | jq -r '.result.content[0].text' | head -20
	@echo ""
	@echo "Testing list_directory for '/workspace'..."
	@curl -s -X POST http://localhost:8080/mcp \
		-H "Content-Type: application/json" \
		-d '{"jsonrpc":"2.0","id":4,"method":"tools/call","params":{"name":"list_directory","arguments":{"path":"."}}}' | jq -r '.result.content[0].text' | head -15
