# Web Tool

**Search the web and fetch HTTP content**

The Web Tool provides HTTP client capabilities for Language Operator agents, including web search via DuckDuckGo, URL fetching, header inspection, and full API request capabilities with retry logic.

## Overview

- **Type:** MCP Server
- **Deployment Mode:** Service
- **Port:** 80
- **Search Provider:** DuckDuckGo
- **Security:** Network egress controls via Kubernetes NetworkPolicy

## Use Cases

### Web Search & Research
```yaml
apiVersion: langop.io/v1alpha1
kind: LanguageAgent
metadata:
  name: research-assistant
spec:
  instructions: |
    Search for latest security advisories and summarize findings
  tools:
  - web
  - email
```

**Perfect for:**
- Researching topics and gathering information
- Monitoring news and updates
- Finding relevant documentation
- Competitive intelligence gathering

### HTTP API Integration
```yaml
apiVersion: langop.io/v1alpha1
kind: LanguageAgent
metadata:
  name: api-monitor
spec:
  instructions: |
    Check API health and report any issues
  tools:
  - web
  - workspace
```

**Perfect for:**
- API health monitoring
- Webhook integrations
- Data fetching from REST APIs
- External service integration

### Content Monitoring
```yaml
apiVersion: langop.io/v1alpha1
kind: LanguageAgent
metadata:
  name: content-watcher
spec:
  instructions: |
    Monitor competitor blog for new posts daily
  tools:
  - web
  - workspace
  - email
```

**Perfect for:**
- Website change detection
- RSS/blog monitoring
- Price tracking
- Availability checking

---

## Tools

The Web Tool exposes 8 MCP tools for web operations:

### 1. web_search

Search the web using DuckDuckGo and return results.

**Parameters:**
- `query` (string, required) - The search query
- `max_results` (number, optional) - Maximum number of results to return (default: 5)

**Returns:** Formatted search results with titles and URLs

**Examples:**

Basic search:
```json
{
  "name": "web_search",
  "arguments": {
    "query": "kubernetes best practices"
  }
}
```

Limit results:
```json
{
  "name": "web_search",
  "arguments": {
    "query": "golang error handling",
    "max_results": 10
  }
}
```

**Output Format:**
```
Search results for: kubernetes best practices

1. Kubernetes Best Practices - Official Documentation
   URL: https://kubernetes.io/docs/best-practices/

2. 10 Best Practices for Kubernetes
   URL: https://example.com/k8s-practices

3. Production-Ready Kubernetes
   URL: https://example.com/prod-k8s
```

**Error Handling:**
- Failed to fetch results → `Error: Failed to fetch search results - <reason>`
- No results found → `No results found for: <query>`

---

### 2. web_fetch

Fetch and extract text content from a URL.

**Parameters:**
- `url` (string, required) - The URL to fetch
- `html` (boolean, optional) - Return raw HTML instead of text (default: false)

**Returns:** Text content or raw HTML

**Examples:**

Fetch as text:
```json
{
  "name": "web_fetch",
  "arguments": {
    "url": "https://example.com/article"
  }
}
```

Fetch as HTML:
```json
{
  "name": "web_fetch",
  "arguments": {
    "url": "https://example.com/page",
    "html": true
  }
}
```

**Behavior:**
- Follows redirects automatically
- Strips HTML tags for text output
- Normalizes whitespace
- Truncates output to 2000 characters
- Sends `User-Agent: Mozilla/5.0` header

**Error Handling:**
- Invalid URL → `Error: Invalid URL. Must start with http:// or https://`
- Failed to fetch → `Error: Failed to fetch URL: <url> - <reason>`
- No content → `No text content found at: <url>`

---

### 3. web_headers

Fetch HTTP headers from a URL.

**Parameters:**
- `url` (string, required) - The URL to check

**Returns:** Formatted HTTP headers

**Examples:**

Check headers:
```json
{
  "name": "web_headers",
  "arguments": {
    "url": "https://api.example.com/v1/health"
  }
}
```

**Output Format:**
```
Headers for https://api.example.com/v1/health:

content-type: application/json
content-length: 42
cache-control: no-cache
x-request-id: abc123
server: nginx/1.21.0
```

**Error Handling:**
- Invalid URL → `Error: Invalid URL. Must start with http:// or https://`
- Failed to fetch → `Error: Failed to fetch headers from: <url> - <reason>`

---

### 4. web_status

Check the HTTP status code of a URL.

**Parameters:**
- `url` (string, required) - The URL to check

**Returns:** HTTP status code and description

**Examples:**

Check status:
```json
{
  "name": "web_status",
  "arguments": {
    "url": "https://api.example.com/health"
  }
}
```

**Output Format:**
```
Status for https://api.example.com/health: 200 OK
```

**Behavior:**
- Does NOT follow redirects (returns actual status)
- Returns status for redirects (301, 302, etc.)

**Status Codes:**
- 200 OK
- 201 Created
- 204 No Content
- 301 Moved Permanently
- 302 Found (Redirect)
- 304 Not Modified
- 400 Bad Request
- 401 Unauthorized
- 403 Forbidden
- 404 Not Found
- 422 Unprocessable Entity
- 429 Too Many Requests
- 500 Internal Server Error
- 502 Bad Gateway
- 503 Service Unavailable
- 504 Gateway Timeout

---

### 5. web_request

Make HTTP requests to APIs with full control over method, headers, body, and retries.

**Parameters:**
- `url` (string, required) - The URL to request
- `method` (string, optional) - HTTP method (GET, POST, PUT, DELETE, HEAD) - default: GET
- `headers` (string, optional) - JSON object of headers
- `body` (string, optional) - Request body (for POST, PUT)
- `query_params` (string, optional) - JSON object of query parameters
- `timeout` (number, optional) - Request timeout in seconds (default: 30)
- `max_retries` (number, optional) - Maximum retries for transient failures (default: 3)
- `follow_redirects` (boolean, optional) - Follow HTTP redirects (default: true)

**Returns:** Full HTTP response with status, headers, and body

**Examples:**

GET request:
```json
{
  "name": "web_request",
  "arguments": {
    "url": "https://api.example.com/users",
    "method": "GET"
  }
}
```

POST with JSON:
```json
{
  "name": "web_request",
  "arguments": {
    "url": "https://api.example.com/users",
    "method": "POST",
    "headers": "{\"Authorization\": \"Bearer token123\", \"Content-Type\": \"application/json\"}",
    "body": "{\"name\": \"John Doe\", \"email\": \"john@example.com\"}"
  }
}
```

With query parameters:
```json
{
  "name": "web_request",
  "arguments": {
    "url": "https://api.example.com/search",
    "query_params": "{\"q\": \"kubernetes\", \"limit\": \"10\"}"
  }
}
```

Custom timeout and retries:
```json
{
  "name": "web_request",
  "arguments": {
    "url": "https://slow-api.example.com/data",
    "timeout": 60,
    "max_retries": 5
  }
}
```

**Output Format:**
```
HTTP GET https://api.example.com/users
Status: 200 OK

Headers:
  content-type: application/json
  cache-control: max-age=300

Body:
{
  "users": [
    {"id": 1, "name": "Alice"},
    {"id": 2, "name": "Bob"}
  ]
}
```

**Retry Logic:**
- Retries on status codes: 429, 500, 502, 503, 504
- Exponential backoff with jitter
- Base delay: 1 second
- Max delay: 10 seconds
- Default max retries: 3

**Error Handling:**
- Invalid URL → `Error: Invalid URL. Must start with http:// or https://`
- Invalid method → `Error: Invalid HTTP method '<method>'. Must be one of: GET, POST, PUT, DELETE, HEAD`
- Invalid JSON in headers → `Error: Invalid JSON in headers parameter`
- Invalid JSON in query_params → `Error: Invalid JSON in query_params parameter`
- Request failed → `Error: Request failed after <N> attempts - <reason>`

---

### 6. web_post

Simplified POST request for JSON APIs.

**Parameters:**
- `url` (string, required) - The URL to POST to
- `data` (string, required) - JSON object to send as request body
- `headers` (string, optional) - Additional headers as JSON object (Content-Type: application/json is set automatically)
- `timeout` (number, optional) - Request timeout in seconds (default: 30)

**Returns:** HTTP response with status and body

**Examples:**

Simple POST:
```json
{
  "name": "web_post",
  "arguments": {
    "url": "https://api.example.com/webhook",
    "data": "{\"event\": \"deployment\", \"status\": \"success\"}"
  }
}
```

With custom headers:
```json
{
  "name": "web_post",
  "arguments": {
    "url": "https://api.example.com/data",
    "data": "{\"key\": \"value\"}",
    "headers": "{\"Authorization\": \"Bearer token123\", \"X-Request-ID\": \"abc\"}"
  }
}
```

**Output Format:**
```
POST https://api.example.com/webhook
Status: 200 OK

Response:
{
  "success": true,
  "id": "12345"
}
```

**Error Handling:**
- Invalid URL → `Error: Invalid URL. Must start with http:// or https://`
- Invalid JSON in data → `Error: Invalid JSON in data parameter`
- Invalid JSON in headers → `Error: Invalid JSON in headers parameter`
- POST failed → `Error: POST failed - <reason>`

---

### 7. web_parse

Parse and extract data from HTTP response body (JSON, XML, or text).

**Parameters:**
- `url` (string, required) - The URL to fetch and parse
- `format` (string, optional) - Expected format: json, xml, or text (auto-detected if not specified)
- `json_path` (string, optional) - JSON path to extract (e.g., 'data.items' for nested field)

**Returns:** Parsed and formatted content

**Examples:**

Auto-detect and parse JSON:
```json
{
  "name": "web_parse",
  "arguments": {
    "url": "https://api.example.com/data.json"
  }
}
```

Extract nested JSON field:
```json
{
  "name": "web_parse",
  "arguments": {
    "url": "https://api.example.com/response.json",
    "format": "json",
    "json_path": "data.users"
  }
}
```

Parse as text:
```json
{
  "name": "web_parse",
  "arguments": {
    "url": "https://example.com/page.html",
    "format": "text"
  }
}
```

**JSON Path Syntax:**
- `data` - Top-level field
- `data.users` - Nested field
- `data.items.0` - Array element by index

**Error Handling:**
- Invalid URL → `Error: Invalid URL. Must start with http:// or https://`
- Failed to fetch → `Error: Failed to fetch URL - <reason>`
- Empty response → `Error: Empty response body`
- Invalid JSON → `Error: Invalid JSON in response body`
- JSON path not found → `Error: JSON path '<path>' not found`
- Unsupported format → `Error: Unsupported format '<format>'. Use json, xml, or text`

---

## Network Security

### Egress Control

The Web Tool requires explicit network egress rules:

```yaml
apiVersion: langop.io/v1alpha1
kind: LanguageTool
metadata:
  name: web
spec:
  image: ghcr.io/language-operator/web-tool:latest
  egress:
  # Allow DuckDuckGo for search
  - description: Allow HTTPS to DuckDuckGo
    dns:
    - "*.duckduckgo.com"
    - duckduckgo.com
    ports:
    - port: 443
      protocol: TCP

  # Allow general web access
  - description: Allow HTTPS to any web destination
    dns:
    - "*"
    ports:
    - port: 443
      protocol: TCP
    - port: 80
      protocol: TCP
```

### Restricted Access

Limit to specific domains:

```yaml
egress:
- description: Allow specific API
  dns:
  - "api.example.com"
  ports:
  - port: 443
    protocol: TCP
```

---

## Deployment

### As a LanguageTool

```yaml
apiVersion: langop.io/v1alpha1
kind: LanguageTool
metadata:
  name: web
spec:
  image: ghcr.io/language-operator/web-tool:latest
  deploymentMode: service
  port: 80
  type: mcp
  egress:
  - description: Allow HTTPS to DuckDuckGo
    dns:
    - "*.duckduckgo.com"
    ports:
    - port: 443
      protocol: TCP
  - description: Allow HTTPS to any web destination
    dns:
    - "*"
    ports:
    - port: 443
      protocol: TCP
```

### Agent Configuration

```yaml
apiVersion: langop.io/v1alpha1
kind: LanguageAgent
metadata:
  name: web-researcher
spec:
  instructions: |
    Search for information and fetch relevant content
  tools:
  - web
  - workspace
```

---

## MCP Protocol Compliance

### Initialization

```json
POST /mcp
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "initialize",
  "params": {
    "protocolVersion": "2024-11-05",
    "capabilities": {},
    "clientInfo": {"name": "agent", "version": "1.0"}
  }
}
```

Response:
```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "protocolVersion": "2024-11-05",
    "serverInfo": {
      "name": "web-tool",
      "version": "1.0.0"
    },
    "capabilities": {
      "tools": {}
    }
  }
}
```

---

## Health Check

```bash
curl http://web.default.svc.cluster.local/health
```

Response:
```json
{
  "status": "ok",
  "service": "web-tool",
  "version": "1.0.0"
}
```

---

## Testing

### Manual Testing

```bash
# Test web search
curl -X POST http://localhost:8080/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"web_search","arguments":{"query":"kubernetes","max_results":3}}}'

# Test web fetch
curl -X POST http://localhost:8080/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"web_fetch","arguments":{"url":"https://example.com"}}}'

# Test web status
curl -X POST http://localhost:8080/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"web_status","arguments":{"url":"https://google.com"}}}'
```

### Automated Tests

```bash
cd web
bundle install
bundle exec rspec
```

---

## Best Practices

1. **Always handle errors**: Network requests can fail
2. **Use appropriate tools**: `web_post` for simple JSON, `web_request` for complex needs
3. **Set reasonable timeouts**: Don't wait forever
4. **Implement retries**: Use `max_retries` for transient failures
5. **Validate URLs**: Check format before making requests
6. **Parse responses**: Use `web_parse` for structured data
7. **Respect rate limits**: Add delays if making many requests
8. **Use HTTPS**: Prefer `https://` over `http://` for security

---

## Version

**Current Version:** 1.0.0

**MCP Protocol:** 2024-11-05

**Language Operator Compatibility:** v0.2.0+

---

## License

MIT License - see [LICENSE](../LICENSE)
