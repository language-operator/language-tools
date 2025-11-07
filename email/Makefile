# Email Tool Makefile
# This Makefile uses the shared tools.mk for common targets

# Image configuration
IMAGE_NAME := git.theryans.io/language-operator/email-tool
TOOL_NAME := email

# SMTP configuration for testing (override these)
SMTP_HOST ?= smtp.example.com
SMTP_PORT ?= 587
SMTP_USER ?= user@example.com
SMTP_PASSWORD ?= password
SMTP_FROM ?= $(SMTP_USER)

# Docker environment variables for SMTP
EXTRA_DOCKER_ENV := \
	-e SMTP_HOST=$(SMTP_HOST) \
	-e SMTP_PORT=$(SMTP_PORT) \
	-e SMTP_USER=$(SMTP_USER) \
	-e SMTP_PASSWORD=$(SMTP_PASSWORD) \
	-e SMTP_FROM=$(SMTP_FROM)

# Include shared targets
include ../tools.mk

# Override help to add SMTP configuration info
.PHONY: help
help:
	@echo "Available targets:"
	@echo "  build     - Build the Docker image"
	@echo "  scan      - Scan the Docker image with Trivy"
	@echo "  shell     - Run the image and exec into it with an interactive shell"
	@echo "  env       - Display sorted list of environment variables in the image"
	@echo "  run       - Run the $(TOOL_NAME) MCP server on port 8080"
	@echo "  spec      - Run RSpec unit tests"
	@echo "  test      - Run the server and test the $(TOOL_NAME) endpoints"
	@echo "  lint      - Run RuboCop linter"
	@echo "  lint-fix  - Auto-fix RuboCop issues"
	@echo "  doc       - Generate YARD documentation"
	@echo "  doc-serve - Generate and serve YARD documentation"
	@echo "  doc-clean - Remove generated documentation"
	@echo "  clean     - Remove all generated files"
	@echo ""
	@echo "SMTP Configuration (set via environment):"
	@echo "  SMTP_HOST     - SMTP server hostname"
	@echo "  SMTP_PORT     - SMTP port (default: 587)"
	@echo "  SMTP_USER     - SMTP username"
	@echo "  SMTP_PASSWORD - SMTP password"
	@echo "  SMTP_FROM     - Default from address"

# Email-specific test target
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
	@echo "Checking email configuration..."
	@curl -s -X POST http://localhost:8080/mcp \
		-H "Content-Type: application/json" \
		-d '{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"email_config","arguments":{}}}' | jq -r '.result.content[0].text'
	@echo ""
	@echo "Note: To test actual email sending, configure SMTP credentials and use:"
	@echo "  curl -X POST http://localhost:8080/mcp \\"
	@echo "    -H 'Content-Type: application/json' \\"
	@echo "    -d '{\"jsonrpc\":\"2.0\",\"id\":4,\"method\":\"tools/call\",\"params\":{\"name\":\"send_email\",\"arguments\":{\"to\":\"recipient@example.com\",\"subject\":\"Test\",\"body\":\"Hello World\"}}}'"
