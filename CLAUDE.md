# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is the Language Operator Tools repository - a collection of MCP (Model Context Protocol) servers that provide specialized capabilities to Language Operator agents. Each tool is packaged as a Docker container that exposes MCP protocol endpoints. Tools fall into two categories:

1. **Ruby-based tools** (`web`, `email`, `k8s`): Custom implementations using the Language Operator Ruby SDK
2. **Wrapper tools** (`filesystem`, `thinking`, `memory`, `time`, `shell`): Official MCP servers wrapped with Python HTTP bridges to convert stdio to HTTP/JSON-RPC

## Key Commands

### Build and Development

```bash
# Build all tools
make build-all

# Build a single tool (note: some tools use different directory names)
cd <tool-name> && make build
# Available tools: web, email, k8s, filesystem, thinking, memory, time, shell

# Compile tool registry index from manifests
make build

# Validate tool manifests
make validate

# Clean generated files
make clean
```

### Individual Tool Development

```bash
# Navigate to any tool directory (web/, email/, k8s/, filesystem/, thinking/, memory/, time/, shell/)
cd web/

# Run unit tests (must be in tool directory, Ruby-based tools only)
make spec
# or: bundle exec rspec

# Run a single test file
bundle exec rspec spec/tools/web_fetch_spec.rb

# Run a specific test
bundle exec rspec spec/tools/web_fetch_spec.rb:42

# Run linting (Ruby-based tools only)
make lint
# or: bundle exec rubocop

# Auto-fix linting issues
make lint-fix
# or: bundle exec rubocop -A

# Build and run tool locally
make build
make run

# Test tool endpoints (requires running server)
make test

# Generate documentation
make doc

# Interactive shell in container
make shell
```

### Testing MCP Tools

Tools run on port 80 in containers (mapped to 8080 locally):

```bash
# Health check
curl http://localhost:8080/health

# MCP protocol - initialize session
curl -X POST http://localhost:8080/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}}'

# List available tools
curl -X POST http://localhost:8080/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}'

# Call a tool
curl -X POST http://localhost:8080/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"tool_name","arguments":{...}}}'
```

## Architecture

### Repository Structure

- **Root level**: `Makefile` for building all tools, `index.yaml` (generated tool registry), `tools.mk` (shared Makefile)
- **Tool directories**: `web/`, `email/`, `k8s/`, `filesystem/`, `thinking/`, `memory/`, `time/`, `shell/` - each contains a complete MCP server
- **scripts/**: `compile-index.rb` - generates the unified tool registry from individual manifests

### Individual Tool Structure

**Ruby-based tools** (`web`, `email`, `k8s`) follow this pattern:

```
tool-name/
├── Dockerfile           # Container image definition
├── Gemfile             # Ruby dependencies (includes language-operator gem)
├── Makefile            # Includes ../tools.mk for standard targets
├── manifest.yaml       # Tool metadata, deployment config, RBAC, egress rules
├── README.md           # Tool-specific documentation
├── tools/              # Tool implementations using SDK DSL
│   └── *.rb
└── spec/              # RSpec unit tests
    └── tools/
        └── *_spec.rb
```

**Wrapper tools** (`filesystem`, `thinking`, `memory`, `time`, `shell`) follow a simpler pattern:

```
tool-name/
├── Dockerfile           # Extends official MCP image, adds Python bridge
├── http-bridge.py       # Python script to convert stdio MCP to HTTP/JSON-RPC
├── Makefile            # Includes ../tools.mk for standard targets
├── manifest.yaml       # Tool metadata, deployment config, RBAC, egress rules
└── README.md           # Tool-specific documentation
```

### Tool Implementation Pattern

**Ruby-based tools** are implemented using the Language Operator Ruby SDK's declarative DSL:

```ruby
# In tools/*.rb files
require 'language_operator'

tool "tool_name" do
  description "What this tool does"
  
  parameter "param_name" do
    type :string
    required true
    description "Parameter documentation"
  end
  
  execute do |params|
    # Tool implementation using SDK utilities:
    # - LanguageOperator::Kubernetes::Client for K8s API
    # - LanguageOperator::Dsl::HTTP for HTTP requests
    # - Helper modules for shared logic

    "Result: #{params['param_name']}"
  end
end
```

**Wrapper tools** use official MCP servers with a Python HTTP bridge (`http-bridge.py`) that:
- Starts the official MCP server as a subprocess with stdio communication
- Exposes an HTTP endpoint on port 80 that accepts JSON-RPC requests
- Forwards requests to the stdio MCP server and returns responses
- Uses only Python standard library (no dependencies)

### Available Tools

**Ruby-based tools:**
1. **web**: Web search (DuckDuckGo), HTTP client, content fetching and parsing (7 MCP tools)
2. **email**: SMTP email sending, configuration testing (3 MCP tools)
3. **k8s**: Full Kubernetes API access, pod operations, resource CRUD

**Wrapper tools (official MCP servers):**
4. **filesystem**: Advanced file operations using official MCP filesystem server (17 tools: edit_file with diffs, directory trees, media files, multi-file reads)
5. **thinking**: Sequential thinking and structured reasoning from official MCP sequential thinking server
6. **memory**: Persistent knowledge graph with entities, relations, and observations from official MCP memory server
7. **time**: Time and timezone conversion using IANA timezone names from official MCP time server
8. **shell**: Secure shell command execution via shell-mcp-server with directory restrictions (`/workspace`, `/tmp`) and 30-second timeout

### MCP Protocol Implementation

All tools expose:
- `/mcp` endpoint for JSON-RPC MCP protocol (port 80 in container)
- `/health` endpoint for health checks
- Standard MCP methods: `initialize`, `tools/list`, `tools/call`

### Integration with Language Operator

- Tools are deployed as `LanguageTool` CRDs in Kubernetes
- Agents declare tool dependencies in their spec (`tools: [web, email]`)
- Tools are discovered via service DNS and called over HTTP using MCP protocol
- RBAC permissions are defined in tool manifests

### Key SDK Components

The `language-operator` Ruby gem provides:
- Tool DSL for defining MCP tools
- Kubernetes client with CRD support
- HTTP utilities with retries and error handling
- MCP protocol server implementation
- Automatic tool discovery and registration

## Tool-Specific Notes

### Web Tool (`web/`)
- 7 MCP tools: web_search, web_fetch, web_headers, web_status, web_request, web_post, web_parse
- Uses DuckDuckGo for search, supports full HTTP operations
- Network egress to any HTTPS/HTTP destination

### Filesystem Tool (`filesystem/`)
- Wraps official MCP filesystem server with 17 advanced tools
- Features: edit_file with diffs, directory trees, media files, multi-file reads
- Provides persistent file storage at `/workspace`
- Deployed as sidecar with shared volume

### K8s Tool (`k8s/`)
- Full Kubernetes API access for cluster operations
- Pod management, resource CRUD operations
- Requires appropriate RBAC permissions

### Thinking Tool (`thinking/`)
- Wraps official MCP sequential thinking server
- Structured, step-by-step reasoning with revision capabilities
- Dynamic problem-solving with branching logic and hypothesis testing
- No external dependencies - pure reasoning tool

### Memory Tool (`memory/`)
- Wraps official MCP memory server with knowledge graph capabilities
- Persistent entity-relationship storage using JSONL format
- Enables agents to remember information across conversations
- Deployed as sidecar with persistent volume for memory retention

### Time Tool (`time/`)
- Wraps official MCP time server with timezone conversion capabilities
- IANA timezone support with automatic DST handling
- Current time queries and timezone conversions
- No external dependencies - pure time calculation tool

### Shell Tool (`shell/`)
- Secure bash command execution using shell-mcp-server
- Directory restrictions to `/workspace` and `/tmp` only
- 30-second timeout protection for all commands
- Common CLI tools pre-installed (curl, wget, git, jq)

## Development Workflow

1. **First-time setup**: Run `./.githooks/install-hooks.sh` to install git hooks
2. **For Ruby-based tools** (`web`, `email`, `k8s`):
   - Make changes to tool implementations in `tools/*.rb`
   - Update tests in `spec/tools/*_spec.rb`
   - Run `make spec` and `make lint` to validate changes
3. **For wrapper tools** (`filesystem`, `thinking`, `memory`, `time`, `shell`):
   - Modify `Dockerfile` to update base image versions
   - Update `http-bridge.py` only if changing the bridge logic (rare)
   - No unit tests (relies on official MCP server tests)
4. Test locally with `make build && make run && make test`
5. Update `manifest.yaml` if adding new egress rules or RBAC requirements
6. Commit changes - `index.yaml` will be automatically rebuilt by pre-commit hook

Always run linting and tests (for Ruby tools) before committing. The repository uses RuboCop for code style and RSpec for unit testing.

### Git Hooks

The repository includes a pre-commit hook that automatically rebuilds `index.yaml` when `manifest.yaml` files change. This ensures the tool registry stays in sync with individual tool configurations.

## Important Notes
- **Dependencies**: Ruby-based tools depend on the `language-operator` gem which provides the core SDK. Wrapper tools only depend on Python 3 standard library and the official MCP server they wrap.
- **Testing**: Ruby-based tools have RSpec unit tests. Wrapper tools rely on official MCP server tests.
- **Documentation**: Ruby-based tools support YARD documentation generation via `make doc`
- **HTTP Bridge**: Wrapper tools use a lightweight Python script (`http-bridge.py`) to convert stdio MCP protocol to HTTP/JSON-RPC, enabling them to work with Language Operator's HTTP-based architecture