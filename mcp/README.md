# MCP Bridge Tool

**Universal bridge to the entire MCP ecosystem**

The MCP Bridge Tool enables Language Operator agents to discover and use any MCP server deployed in the cluster, providing infinite extensibility through the Model Context Protocol ecosystem.

## Overview

- **Type:** MCP Server
- **Deployment Mode:** Service
- **Port:** 80
- **Purpose:** Universal MCP client for agent-to-server communication
- **Discovery:** Automatic via LanguageTool CRDs
- **Protocol:** MCP 2024-11-05

## Use Cases

### Multi-Tool Workflows
```yaml
apiVersion: langop.io/v1alpha1
kind: LanguageAgent
metadata:
  name: multi-tool-agent
spec:
  instructions: |
    Use mcp_discover to find available tools.
    Chain operations across multiple MCP servers.
  tools:
  - mcp
```

**Perfect for:**
- Dynamic tool discovery
- Cross-tool workflows
- Third-party MCP integration
- Custom tool development

### Third-Party MCP Servers
```yaml
apiVersion: langop.io/v1alpha1
kind: LanguageAgent
metadata:
  name: github-agent
spec:
  instructions: |
    Use the GitHub MCP server to manage repositories
  tools:
  - mcp
```

**Perfect for:**
- GitHub operations (via MCP server)
- Slack integration (via MCP server)
- Database access (via MCP server)
- Any MCP-compatible service

### Tool Composition
```yaml
apiVersion: langop.io/v1alpha1
kind: LanguageAgent
metadata:
  name: composer
spec:
  instructions: |
    Discover available MCP tools and compose complex workflows
  tools:
  - mcp
  - workspace
```

**Perfect for:**
- Dynamic capability composition
- Plugin-based architectures
- Extensible automation
- Multi-vendor integration

---

## Tools

The MCP Bridge Tool exposes 4 MCP tools for universal MCP server access:

### 1. mcp_discover

Discover MCP servers available in the Kubernetes cluster via LanguageTool CRDs.

**Parameters:** None

**Returns:** List of all MCP servers with metadata

**Examples:**

Discover all servers:
```json
{
  "name": "mcp_discover",
  "arguments": {}
}
```

**Output Format:**
```
Found 5 MCP server(s):

• email
  Display Name: Email Tool
  Description: Send and receive emails via SMTP/IMAP
  Namespace: default
  Endpoint: http://email.default.svc.cluster.local:80/mcp

• web
  Display Name: Web Tool
  Description: Web browsing and HTTP client
  Namespace: default
  Endpoint: http://web.default.svc.cluster.local:80/mcp

• workspace
  Display Name: Workspace Tool
  Description: Persistent file I/O for agent workspace
  Namespace: default
  Endpoint: http://workspace.default.svc.cluster.local:80/mcp

• k8s
  Display Name: Kubernetes Tool
  Description: Full Kubernetes API access
  Namespace: default
  Endpoint: http://k8s.default.svc.cluster.local:80/mcp

• github
  Display Name: GitHub MCP Server
  Description: GitHub repository management
  Namespace: integrations
  Endpoint: http://github.integrations.svc.cluster.local:80/mcp
```

**Error Handling:**
- No servers found → `No MCP servers found in cluster`
- Access denied → `Error: Access denied - check RBAC permissions for LanguageTool CRDs`
- Connection failed → `Error: Failed to discover MCP servers: <reason>`

---

### 2. mcp_list_tools

List all tools exposed by a specific MCP server.

**Parameters:**
- `server` (string, required) - Name of the MCP server (from mcp_discover)

**Returns:** List of tools with descriptions and parameters

**Examples:**

List email tools:
```json
{
  "name": "mcp_list_tools",
  "arguments": {
    "server": "email"
  }
}
```

List custom server tools:
```json
{
  "name": "mcp_list_tools",
  "arguments": {
    "server": "github"
  }
}
```

**Output Format:**
```
Tools from Email Tool:

Found 3 tool(s):

• send_email
  Description: Send an email via SMTP
  Parameters: to, subject, body, from, cc, bcc, html

• test_smtp
  Description: Test SMTP connection and configuration

• email_config
  Description: Display current email configuration (without sensitive data)
```

For GitHub server:
```
Tools from GitHub MCP Server:

Found 8 tool(s):

• create_repository
  Description: Create a new GitHub repository
  Parameters: name, description, private, auto_init

• create_issue
  Description: Create an issue in a repository
  Parameters: owner, repo, title, body, labels

• list_issues
  Description: List issues in a repository
  Parameters: owner, repo, state, labels

• create_pull_request
  Description: Create a pull request
  Parameters: owner, repo, title, body, head, base
```

**Error Handling:**
- Server not found → `Error: Server 'github' not found. Use mcp_discover to see available servers.`
- Connection failed → `Error: Connection error: <reason>`
- Server error → `Error: HTTP 500: Failed to list tools`

---

### 3. mcp_call

Call a tool from any registered MCP server with specified arguments.

**Parameters:**
- `server` (string, required) - Name of the MCP server
- `tool` (string, required) - Name of the tool to call
- `arguments` (object, optional) - Arguments to pass to the tool (as JSON object)

**Returns:** Tool execution result

**Examples:**

Send email via MCP:
```json
{
  "name": "mcp_call",
  "arguments": {
    "server": "email",
    "tool": "send_email",
    "arguments": {
      "to": "admin@example.com",
      "subject": "Alert from Agent",
      "body": "System health check completed successfully"
    }
  }
}
```

Search web via MCP:
```json
{
  "name": "mcp_call",
  "arguments": {
    "server": "web",
    "tool": "web_search",
    "arguments": {
      "query": "kubernetes best practices",
      "max_results": 5
    }
  }
}
```

Create GitHub issue:
```json
{
  "name": "mcp_call",
  "arguments": {
    "server": "github",
    "tool": "create_issue",
    "arguments": {
      "owner": "myorg",
      "repo": "myproject",
      "title": "Automated bug report",
      "body": "Agent detected error in logs at 14:30 UTC"
    }
  }
}
```

Tool with no arguments:
```json
{
  "name": "mcp_call",
  "arguments": {
    "server": "email",
    "tool": "test_smtp"
  }
}
```

**Output Format:**

For text responses:
```
Email sent successfully to admin@example.com
```

For structured data:
```
Issue created: https://github.com/myorg/myproject/issues/42
```

For complex responses:
```
Search Results:
1. Kubernetes Best Practices - kubernetes.io
   Production-grade container orchestration...

2. 10 Kubernetes Best Practices - cloud.google.com
   Learn the best practices for running Kubernetes...
```

**Error Handling:**
- Server not found → `Error: Server 'github' not found. Use mcp_discover to see available servers.`
- Tool error → `Tool Error: <error message from tool>`
- Invalid arguments → `MCP Error -32602: Invalid params`
- Connection failed → `Error: Connection error: timeout`

---

### 4. mcp_server_info

Get detailed information about an MCP server including capabilities and metadata.

**Parameters:**
- `server` (string, required) - Name of the MCP server

**Returns:** Server information, version, protocol, and capabilities

**Examples:**

Get email server info:
```json
{
  "name": "mcp_server_info",
  "arguments": {
    "server": "email"
  }
}
```

Get custom server info:
```json
{
  "name": "mcp_server_info",
  "arguments": {
    "server": "github"
  }
}
```

**Output Format:**
```
Server: Email Tool
Description: Send and receive emails via SMTP/IMAP
Endpoint: http://email.default.svc.cluster.local:80/mcp

Server Information:
  Name: email-tool
  Version: 1.0.0

Protocol Version: 2024-11-05

Capabilities:
  Tools: supported
  Resources: not supported
  Prompts: not supported
```

For servers with additional capabilities:
```
Server: GitHub MCP Server
Description: GitHub repository management
Endpoint: http://github.integrations.svc.cluster.local:80/mcp

Server Information:
  Name: github-mcp
  Version: 2.3.1

Protocol Version: 2024-11-05

Capabilities:
  Tools: supported
  Resources: supported
  Prompts: supported
```

**Error Handling:**
- Server not found → `Error: Server 'unknown' not found. Use mcp_discover to see available servers.`
- Connection failed → `Error: Connection error: <reason>`
- Protocol error → `Error: MCP Error -32700: Parse error`

---

## Configuration

### RBAC Permissions

The MCP Bridge Tool requires read access to LanguageTool CRDs to discover available MCP servers:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: mcp-tool
  namespace: default
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: mcp-tool
rules:
- apiGroups: ["langop.io"]
  resources: ["languagetools"]
  verbs: ["get", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: mcp-tool
subjects:
- kind: ServiceAccount
  name: mcp-tool
  namespace: default
roleRef:
  kind: ClusterRole
  name: mcp-tool
  apiGroup: rbac.authorization.k8s.io
```

### Network Access

The MCP Bridge requires network access to all MCP servers it may call:

```yaml
apiVersion: langop.io/v1alpha1
kind: LanguageTool
metadata:
  name: mcp
spec:
  image: git.theryans.io/language-operator/mcp-tool:latest
  authRequired: true
  egress:
  - description: Allow access to all cluster services
    dns:
    - "*.svc.cluster.local"
    ports:
    - port: 80
      protocol: TCP
    - port: 443
      protocol: TCP
```

### Environment Variables

No environment variables required. The tool uses in-cluster Kubernetes configuration automatically.

---

## Deployment

### As a LanguageTool

```yaml
apiVersion: langop.io/v1alpha1
kind: LanguageTool
metadata:
  name: mcp
spec:
  image: git.theryans.io/language-operator/mcp-tool:latest
  deploymentMode: service
  port: 80
  type: mcp
  authRequired: true
  serviceAccount: mcp-tool
  egress:
  - description: Allow MCP server communication
    dns:
    - "*.svc.cluster.local"
    ports:
    - port: 80
      protocol: TCP
```

### Agent Configuration

```yaml
apiVersion: langop.io/v1alpha1
kind: LanguageAgent
metadata:
  name: multi-tool-agent
spec:
  instructions: |
    Discover available MCP tools and use them to complete tasks
  tools:
  - mcp
  - workspace
```

### Deploying Third-Party MCP Servers

Deploy any MCP-compatible server as a LanguageTool:

```yaml
apiVersion: langop.io/v1alpha1
kind: LanguageTool
metadata:
  name: github
  namespace: integrations
spec:
  image: modelcontextprotocol/server-github:latest
  deploymentMode: service
  port: 80
  type: mcp
  authRequired: true
  env:
  - name: GITHUB_TOKEN
    valueFrom:
      secretKeyRef:
        name: github-credentials
        key: token
```

The MCP Bridge will automatically discover this server via `mcp_discover`.

---

## MCP Server Discovery

### How Discovery Works

1. **CRD Query**: MCP Bridge queries Kubernetes for all LanguageTool CRDs
2. **Type Filter**: Filters for resources where `spec.type == 'mcp'`
3. **Endpoint Build**: Constructs service DNS name from metadata and spec
4. **Metadata Extract**: Extracts display name and description

### Discovered Server Format

```ruby
{
  name: "email",                    # metadata.name
  namespace: "default",              # metadata.namespace
  endpoint: "http://email.default.svc.cluster.local:80/mcp",
  display_name: "Email Tool",        # spec.displayName || metadata.name
  description: "Send and receive emails via SMTP/IMAP"  # spec.description
}
```

### Multi-Namespace Discovery

The MCP Bridge discovers servers across ALL namespaces (requires ClusterRole):

```yaml
rules:
- apiGroups: ["langop.io"]
  resources: ["languagetools"]
  verbs: ["get", "list"]
  # No namespace restriction - cluster-wide access
```

### Custom Ports

Non-standard ports are automatically detected:

```yaml
apiVersion: langop.io/v1alpha1
kind: LanguageTool
metadata:
  name: custom-server
spec:
  port: 8080  # Non-standard port
  type: mcp
```

Discovered as:
```
http://custom-server.default.svc.cluster.local:8080/mcp
```

---

## MCP Protocol Compliance

### Standard MCP Workflow

1. **Initialize**: Establish connection and exchange capabilities
2. **List Tools**: Discover available tools from server
3. **Call Tool**: Execute tool with JSON arguments
4. **Handle Response**: Process result or error

### Protocol Messages

**Initialize:**
```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "initialize",
  "params": {
    "protocolVersion": "2024-11-05",
    "capabilities": {},
    "clientInfo": {"name": "mcp-tool", "version": "1.0.0"}
  }
}
```

**List Tools:**
```json
{
  "jsonrpc": "2.0",
  "id": 2,
  "method": "tools/list",
  "params": {}
}
```

**Call Tool:**
```json
{
  "jsonrpc": "2.0",
  "id": 3,
  "method": "tools/call",
  "params": {
    "name": "send_email",
    "arguments": {
      "to": "user@example.com",
      "subject": "Test",
      "body": "Hello"
    }
  }
}
```

### Error Codes

| Code | Meaning | Example |
|------|---------|---------|
| -32700 | Parse error | Invalid JSON |
| -32600 | Invalid request | Missing required fields |
| -32601 | Method not found | Unknown MCP method |
| -32602 | Invalid params | Wrong parameter types |
| -32603 | Internal error | Server-side error |

---

## Health Check

```bash
curl http://mcp.default.svc.cluster.local/health
```

Response:
```json
{
  "status": "ok",
  "service": "mcp-tool",
  "version": "1.0.0"
}
```

---

## Testing

### Manual Testing

```bash
# Discover servers
curl -X POST http://localhost:8080/mcp \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc":"2.0",
    "id":1,
    "method":"tools/call",
    "params":{"name":"mcp_discover","arguments":{}}
  }'

# List tools from email server
curl -X POST http://localhost:8080/mcp \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc":"2.0",
    "id":2,
    "method":"tools/call",
    "params":{"name":"mcp_list_tools","arguments":{"server":"email"}}
  }'

# Call a tool via bridge
curl -X POST http://localhost:8080/mcp \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc":"2.0",
    "id":3,
    "method":"tools/call",
    "params":{
      "name":"mcp_call",
      "arguments":{
        "server":"email",
        "tool":"test_smtp",
        "arguments":{}
      }
    }
  }'
```

### Automated Tests

```bash
cd mcp
bundle install
bundle exec rspec
```

---

## Common Patterns

### Dynamic Tool Discovery

```yaml
apiVersion: langop.io/v1alpha1
kind: LanguageAgent
metadata:
  name: explorer
spec:
  instructions: |
    When asked to perform a task:
    1. Use mcp_discover to find available servers
    2. Use mcp_list_tools to find relevant tools
    3. Use mcp_server_info to understand capabilities
    4. Use mcp_call to execute the right tool
  tools:
  - mcp
```

### Multi-Server Workflows

```yaml
apiVersion: langop.io/v1alpha1
kind: LanguageAgent
metadata:
  name: orchestrator
spec:
  instructions: |
    Coordinate operations across multiple MCP servers:
    - Fetch data via web server
    - Process and save via workspace server
    - Send notifications via email server
    - Update GitHub via github server
  tools:
  - mcp
```

### Third-Party Integration

```yaml
apiVersion: langop.io/v1alpha1
kind: LanguageAgent
metadata:
  name: github-bot
spec:
  instructions: |
    Use the GitHub MCP server to:
    - Monitor issues
    - Create pull requests
    - Comment on discussions
    - Manage releases
  tools:
  - mcp
  - workspace
```

### Plugin Architecture

```yaml
apiVersion: langop.io/v1alpha1
kind: LanguageAgent
metadata:
  name: plugin-host
spec:
  instructions: |
    Discover and use any MCP plugin dynamically.
    No hardcoded tool dependencies.
  tools:
  - mcp
```

---

## Troubleshooting

### Common Issues

**"No MCP servers found in cluster"**
- Cause: No LanguageTool resources with `type: mcp` exist
- Solution:
  - Deploy MCP servers as LanguageTool resources
  - Verify `spec.type: mcp` is set
  - Check RBAC permissions for listing LanguageTools

**"Error: Server 'X' not found"**
- Cause: Specified server doesn't exist or isn't registered
- Solution:
  - Run `mcp_discover` to see available servers
  - Check server name spelling (case-sensitive)
  - Verify server is deployed and has `type: mcp`

**"Error: Access denied - check RBAC permissions for LanguageTool CRDs"**
- Cause: ServiceAccount lacks permissions to list LanguageTools
- Solution:
  - Apply ClusterRole with LanguageTool read permissions
  - Create ClusterRoleBinding linking ServiceAccount to ClusterRole
  - Verify permissions: `kubectl auth can-i list languagetools --as system:serviceaccount:default:mcp-tool`

**"Connection error: timeout"**
- Cause: Network connectivity to MCP server failed
- Solution:
  - Verify MCP server is running: `kubectl get pods -l app=<server-name>`
  - Check service exists: `kubectl get svc <server-name>`
  - Verify egress rules allow cluster service access
  - Test direct connection: `curl http://<server>.<namespace>.svc.cluster.local/health`

**"MCP Error -32601: Method not found"**
- Cause: Calling unsupported MCP method
- Solution:
  - Use standard MCP methods: initialize, tools/list, tools/call
  - Check server capabilities with `mcp_server_info`
  - Verify tool name is correct with `mcp_list_tools`

**"Tool Error: <message>"**
- Cause: The called tool returned an error
- Solution:
  - Check tool arguments match required schema
  - Verify required parameters are provided
  - Review tool-specific error message
  - Use `mcp_list_tools` to see parameter requirements

---

## Performance Considerations

### Connection Pooling

Each MCP call establishes a new connection:

- **Initialize**: ~100-200ms
- **Tool Call**: ~50-500ms depending on tool
- **Total**: ~150-700ms per operation

For repeated calls to the same server, the overhead is per-call.

### Timeout Configuration

Default timeout is 30 seconds:

```ruby
# In MCPHelpers module
DEFAULT_TIMEOUT = 30
```

For long-running tools, the timeout may need adjustment (future enhancement).

### Concurrent Calls

The MCP Bridge handles concurrent requests independently. Multiple agents can call different servers simultaneously without blocking.

### Discovery Caching

Server discovery queries Kubernetes API on each call. For high-frequency discovery, consider caching in the agent's workspace (future enhancement).

---

## Best Practices

1. **Discover First**: Always use `mcp_discover` before calling unknown servers
2. **List Tools**: Use `mcp_list_tools` to understand available operations
3. **Check Server Info**: Verify capabilities with `mcp_server_info`
4. **Handle Errors**: Always check for and handle tool errors
5. **Validate Arguments**: Ensure arguments match tool schema
6. **Use Workspace**: Cache discovery results to reduce API calls
7. **Document Dependencies**: Note which MCP servers your agent requires
8. **Test Connectivity**: Use `mcp_server_info` as a connectivity test
9. **Handle Timeouts**: Implement retry logic for transient failures
10. **Namespace Awareness**: Consider multi-namespace server deployments

---

## Extending with Custom MCP Servers

### Building a Custom MCP Server

Any service implementing the MCP protocol can be used:

```ruby
# Custom MCP server in Ruby
require 'sinatra'
require 'json'

post '/mcp' do
  request_data = JSON.parse(request.body.read)

  case request_data['method']
  when 'initialize'
    {
      jsonrpc: '2.0',
      id: request_data['id'],
      result: {
        protocolVersion: '2024-11-05',
        serverInfo: { name: 'my-custom-server', version: '1.0.0' },
        capabilities: { tools: {} }
      }
    }.to_json
  when 'tools/list'
    # Return tool definitions...
  when 'tools/call'
    # Execute tool...
  end
end
```

### Deploying Custom Server

```yaml
apiVersion: langop.io/v1alpha1
kind: LanguageTool
metadata:
  name: my-custom-server
spec:
  image: myregistry.com/my-mcp-server:latest
  deploymentMode: service
  port: 80
  type: mcp
  authRequired: true
  displayName: My Custom Server
  description: Custom MCP server for specialized operations
```

### Using Custom Server

```json
{
  "name": "mcp_call",
  "arguments": {
    "server": "my-custom-server",
    "tool": "custom_operation",
    "arguments": {
      "param1": "value1"
    }
  }
}
```

---

## Available Third-Party MCP Servers

### Official MCP Servers

| Server | Image | Purpose |
|--------|-------|---------|
| GitHub | `modelcontextprotocol/server-github` | Repository management |
| Slack | `modelcontextprotocol/server-slack` | Slack messaging |
| Google Drive | `modelcontextprotocol/server-gdrive` | Drive file operations |
| PostgreSQL | `modelcontextprotocol/server-postgres` | Database queries |

### Community Servers

Check the [MCP Server Registry](https://github.com/modelcontextprotocol/servers) for community-built servers.

### Deploying Third-Party Servers

```yaml
apiVersion: langop.io/v1alpha1
kind: LanguageTool
metadata:
  name: slack
  namespace: integrations
spec:
  image: modelcontextprotocol/server-slack:latest
  deploymentMode: service
  port: 80
  type: mcp
  authRequired: true
  displayName: Slack MCP Server
  description: Send messages and manage Slack workspaces
  env:
  - name: SLACK_TOKEN
    valueFrom:
      secretKeyRef:
        name: slack-credentials
        key: token
```

---

## Architecture

### Request Flow

```
Agent → MCP Bridge → Discovery (K8s API) → LanguageTool CRDs
                  ↓
               Target MCP Server → Tool Execution → Result
                  ↓
               Agent ← Response
```

### Components

1. **MCP Bridge Tool**: Universal MCP client
2. **Kubernetes API**: CRD discovery
3. **LanguageTool CRDs**: Server registry
4. **MCP Servers**: Tool providers
5. **Service DNS**: Cluster networking

### Protocol Stack

```
┌─────────────────────────────────┐
│   Language Agent                │
├─────────────────────────────────┤
│   MCP Protocol (JSON-RPC)       │
├─────────────────────────────────┤
│   MCP Bridge Tool               │
├─────────────────────────────────┤
│   Kubernetes Service Discovery  │
├─────────────────────────────────┤
│   HTTP/TCP                      │
├─────────────────────────────────┤
│   Target MCP Server             │
└─────────────────────────────────┘
```

---

## Version

**Current Version:** 1.0.0

**MCP Protocol:** 2024-11-05

**Language Operator Compatibility:** v0.2.0+

**k8s-ruby Version:** ~> 0.11

---

## License

MIT License - see [LICENSE](../LICENSE)
