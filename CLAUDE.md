# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is the Language Operator Tools repository - a collection of MCP (Model Context Protocol) servers that provide specialized capabilities to Language Operator agents. Each tool is implemented as a standalone Ruby service packaged as a Docker container that exposes MCP protocol endpoints.

## Key Commands

### Build and Development

```bash
# Build all tools
make build-all

# Build a single tool (note: some tools use different directory names)
cd <tool-name> && make build
# Available tools: web, email, cron, k8s, mcp, workspace

# Compile tool registry index from manifests
make build

# Validate tool manifests
make validate

# Clean generated files
make clean
```

### Individual Tool Development

```bash
# Navigate to any tool directory (web/, email/, cron/, k8s/, mcp/, workspace/)
cd web/

# Run unit tests (must be in tool directory)
make spec
# or: bundle exec rspec

# Run linting
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
- **Tool directories**: `web/`, `email/`, `cron/`, `k8s/`, `mcp/`, `workspace/` - each contains a complete MCP server
- **scripts/**: `compile-index.rb` - generates the unified tool registry from individual manifests

### Individual Tool Structure

Each tool directory follows this pattern:

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

### Tool Implementation Pattern

Tools are implemented using the Language Operator Ruby SDK's declarative DSL:

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

### Available Tools

1. **web**: Web search (DuckDuckGo), HTTP client, content fetching and parsing
2. **email**: SMTP email sending, configuration testing 
3. **cron**: Self-scheduling, natural language cron parsing, LanguageAgent CRD management
4. **k8s**: Full Kubernetes API access, pod operations, resource CRUD
5. **workspace**: Persistent file I/O for agent state (`/workspace` directory)
6. **mcp**: Meta-tool for discovering and calling other MCP servers

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

### Cron Tool (`cron/`)
- Self-scheduling capabilities, natural language parsing
- Modifies LanguageAgent CRDs to create schedules
- Requires RBAC access to `languageagents` resources

### Workspace Tool (`workspace/`)
- Provides persistent file storage at `/workspace`
- Sandboxed file operations, multi-agent coordination support
- Deployed as sidecar with shared volume

### MCP Bridge Tool (`mcp/`)
- Universal client for any MCP server
- Discovers other tools via LanguageTool CRD queries
- Enables dynamic tool composition

### K8s Tool (`k8s/`)
- Full Kubernetes API access for cluster operations
- Pod management, resource CRUD operations
- Requires appropriate RBAC permissions

## Development Workflow

1. Make changes to tool implementations in `tools/*.rb`
2. Update tests in `spec/tools/*_spec.rb`
3. Run `make spec` and `make lint` to validate changes
4. Test locally with `make build && make run && make test`
5. Update `manifest.yaml` if adding new egress rules or RBAC requirements
6. Rebuild index with `make build` (compiles all manifests into `index.yaml`)

Always run linting and tests before committing. The repository uses RuboCop for code style and RSpec for unit testing.

## Important Notes

- **Directory Structure**: The Makefile refers to a `filesystem` tool, but the actual directory is named `workspace`
- **Dependencies**: All tools depend on the `language-operator` gem which provides the core SDK
- **Testing**: Each tool has integration tests that verify MCP protocol compliance
- **Documentation**: Tools support YARD documentation generation via `make doc`