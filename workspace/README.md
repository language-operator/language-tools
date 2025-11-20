# Workspace Tool

**Persistent file storage for autonomous agents**

The Workspace Tool provides persistent file I/O capabilities for Language Operator agents. It enables agents to read, write, and manage files in a shared workspace that persists across executions, allowing agents to build knowledge over time and maintain state.

## Overview

- **Type:** MCP Server
- **Deployment Mode:** Service
- **Port:** 80
- **Workspace Root:** `/workspace`
- **Security:** All operations are sandboxed within `/workspace` directory

## Use Cases

### State Management
```yaml
apiVersion: langop.io/v1alpha1
kind: LanguageAgent
metadata:
  name: daily-reporter
spec:
  instructions: |
    Track daily metrics and remember what was already reported
  tools:
  - workspace
  - web
```

**Perfect for:**
- Tracking which tasks have been completed
- Remembering the last time an action was performed
- Building incremental knowledge bases
- Storing processed data between runs

### Data Persistence
```yaml
apiVersion: langop.io/v1alpha1
kind: LanguageAgent
metadata:
  name: log-analyzer
spec:
  instructions: |
    Analyze logs and save findings to workspace for trend analysis
  tools:
  - workspace
  - k8s
```

**Perfect for:**
- Saving analysis results
- Building historical datasets
- Caching expensive computations
- Storing configuration and settings

### Multi-Agent Coordination
```yaml
apiVersion: langop.io/v1alpha1
kind: LanguageCluster
metadata:
  name: research-team
spec:
  agents:
  - name: researcher
    tools: [workspace, web]
  - name: analyst
    tools: [workspace]
  sharedWorkspace: true
```

**Perfect for:**
- Sharing data between multiple agents
- Coordinated workflows with handoffs
- Collaborative document creation
- Shared knowledge bases

---

## Tools

The Workspace Tool exposes 6 MCP tools for file operations:

### 1. read_file

Read complete file contents from workspace.

**Parameters:**
- `path` (string, required) - File path relative to /workspace (or absolute path within /workspace)
- `head` (number, optional) - Read only first N lines
- `tail` (number, optional) - Read only last N lines

**Returns:** File contents as text

**Examples:**

Read entire file:
```json
{
  "name": "read_file",
  "arguments": {
    "path": "notes.txt"
  }
}
```

Read first 10 lines:
```json
{
  "name": "read_file",
  "arguments": {
    "path": "logs/app.log",
    "head": 10
  }
}
```

Read last 50 lines:
```json
{
  "name": "read_file",
  "arguments": {
    "path": "data/results.csv",
    "tail": 50
  }
}
```

**Error Handling:**
- File not found → `Error: File not found: <path>`
- Not a file → `Error: Not a file: <path>`
- Permission denied → `Error: File not readable: <path>`
- Invalid UTF-8 → `Error: File contains invalid UTF-8 encoding`
- Outside workspace → `Error: Access denied. Path must be within /workspace`

---

### 2. write_file

Create new file or completely overwrite existing file in workspace.

> **⚠️ IMPORTANT:** This tool replaces the entire file contents. To append to an existing file, you must first read the file, combine the contents, then write back the combined content.

**Parameters:**
- `path` (string, required) - File path relative to /workspace (or absolute path within /workspace)
- `content` (string, required) - Complete file contents to write (replaces any existing content)

**Returns:** Success message with bytes written

**Examples:**

Create new file:
```json
{
  "name": "write_file",
  "arguments": {
    "path": "status.txt",
    "content": "Task completed at 2025-11-07 18:00:00"
  }
}
```

Write multi-line file:
```json
{
  "name": "write_file",
  "arguments": {
    "path": "story.txt",
    "content": "Once upon a time.\nThere was a brave knight.\nThe end."
  }
}
```

Write JSON data:
```json
{
  "name": "write_file",
  "arguments": {
    "path": "data/metrics.json",
    "content": "{\"timestamp\": \"2025-11-07\", \"count\": 42}"
  }
}
```

Create empty file:
```json
{
  "name": "write_file",
  "arguments": {
    "path": "placeholder.txt",
    "content": ""
  }
}
```

**Append Pattern (Read → Combine → Write):**

To add content to an existing file, use this three-step pattern:

```json
// Step 1: Read existing file
{
  "name": "read_file",
  "arguments": {
    "path": "story.txt"
  }
}
// Returns: "Once upon a time.\n"

// Step 2: Combine old content with new content in your code
// combined_content = existing_content + new_sentence

// Step 3: Write combined content back
{
  "name": "write_file",
  "arguments": {
    "path": "story.txt",
    "content": "Once upon a time.\nThere was a brave knight.\n"
  }
}
```

**Behavior:**
- Creates parent directories automatically if they don't exist
- **Overwrites existing files completely** - entire file is replaced
- Writes files with UTF-8 encoding
- Empty string is valid for creating empty files

**Common Mistakes:**

❌ **Don't pass empty arguments:**
```json
{
  "name": "write_file",
  "arguments": {}  // ERROR: Missing required parameters
}
```

✅ **Both parameters are required:**
```json
{
  "name": "write_file",
  "arguments": {
    "path": "file.txt",
    "content": "content here"
  }
}
```

❌ **Don't write just new content when appending:**
```json
// This REPLACES the entire file with just the new sentence!
{
  "name": "write_file",
  "arguments": {
    "path": "story.txt",
    "content": "There was a brave knight.\n"  // Old content is LOST
  }
}
```

✅ **Read first, then write combined content:**
```json
// First read to get existing content
{"name": "read_file", "arguments": {"path": "story.txt"}}
// Then write the complete combined content
{
  "name": "write_file",
  "arguments": {
    "path": "story.txt",
    "content": "Once upon a time.\nThere was a brave knight.\n"
  }
}
```

**Error Handling:**
- Failed to create directory → `Error: Failed to create parent directory - <reason>`
- Write failed → `Error: Failed to write file - <reason>`
- Outside workspace → `Error: Access denied. Path must be within /workspace`

---

### 3. list_directory

List directory contents with file/directory indicators.

**Parameters:**
- `path` (string, required) - Directory path relative to /workspace (or absolute path within /workspace)

**Returns:** Formatted list with `[FILE]` or `[DIR]` indicators

**Examples:**

List workspace root:
```json
{
  "name": "list_directory",
  "arguments": {
    "path": "."
  }
}
```

List subdirectory:
```json
{
  "name": "list_directory",
  "arguments": {
    "path": "data/reports"
  }
}
```

**Output Format:**
```
Contents of data/reports:

[DIR] 2025-11
[DIR] 2025-10
[FILE] summary.txt
[FILE] README.md
```

**Error Handling:**
- Not found → `Error: Directory not found: <path>`
- Not a directory → `Error: Not a directory: <path>`
- Empty directory → `Directory is empty: <path>`
- Outside workspace → `Error: Access denied. Path must be within /workspace`

---

### 4. create_directory

Create new directory in workspace (creates parent directories as needed).

**Parameters:**
- `path` (string, required) - Directory path relative to /workspace (or absolute path within /workspace)

**Returns:** Success message

**Examples:**

Create single directory:
```json
{
  "name": "create_directory",
  "arguments": {
    "path": "logs"
  }
}
```

Create nested directories:
```json
{
  "name": "create_directory",
  "arguments": {
    "path": "data/reports/2025-11"
  }
}
```

**Behavior:**
- Creates all parent directories automatically (like `mkdir -p`)
- Idempotent: succeeds if directory already exists
- Fails if path exists but is not a directory

**Error Handling:**
- Path exists as file → `Error: Path exists but is not a directory: <path>`
- Failed to create → `Error: Failed to create directory - <reason>`
- Outside workspace → `Error: Access denied. Path must be within /workspace`

---

### 5. get_file_info

Get detailed file or directory metadata.

**Parameters:**
- `path` (string, required) - File or directory path relative to /workspace (or absolute path within /workspace)

**Returns:** Formatted metadata including type, size, permissions, timestamps

**Examples:**

Get file info:
```json
{
  "name": "get_file_info",
  "arguments": {
    "path": "data/metrics.json"
  }
}
```

**Output Format:**
```
Path: data/metrics.json
Type: file
Size: 1.23 KB
Permissions: 644
Owner UID: 1000
Owner GID: 1000
Created: 2025-11-07 12:00:00 UTC
Modified: 2025-11-07 18:30:00 UTC
Accessed: 2025-11-07 18:35:00 UTC
```

For directories:
```
Path: data
Type: directory
Permissions: 755
Owner UID: 1000
Owner GID: 1000
Created: 2025-11-07 12:00:00 UTC
Modified: 2025-11-07 18:30:00 UTC
Accessed: 2025-11-07 18:35:00 UTC
Entries: 5
```

**Error Handling:**
- Not found → `Error: Path not found: <path>`
- Failed to read metadata → `Error: Failed to get file info - <reason>`
- Outside workspace → `Error: Access denied. Path must be within /workspace`

---

### 6. search_files

Recursively search for files and directories matching a glob pattern.

**Parameters:**
- `path` (string, required) - Starting directory path relative to /workspace
- `pattern` (string, required) - Glob pattern to match (e.g., '*.rb', '**/*.txt')
- `max_results` (number, optional) - Maximum number of results to return (default: 100)

**Returns:** List of matching paths with file/directory indicators

**Examples:**

Find all JSON files:
```json
{
  "name": "search_files",
  "arguments": {
    "path": ".",
    "pattern": "**/*.json"
  }
}
```

Find log files in specific directory:
```json
{
  "name": "search_files",
  "arguments": {
    "path": "logs",
    "pattern": "*.log",
    "max_results": 50
  }
}
```

Find all directories named "config":
```json
{
  "name": "search_files",
  "arguments": {
    "path": ".",
    "pattern": "**/config"
  }
}
```

**Glob Pattern Syntax:**
- `*` - Match any characters except `/`
- `**` - Match any characters including `/` (recursive)
- `?` - Match single character
- `[abc]` - Match any character in set
- `{a,b}` - Match any alternative

**Output Format:**
```
Found 3 match(es) for '**/*.json':

[FILE] data/metrics.json
[FILE] config/settings.json
[FILE] results/output.json
```

**Error Handling:**
- Directory not found → `Error: Directory not found: <path>`
- Not a directory → `Error: Not a directory: <path>`
- Search failed → `Error: Search failed - <reason>`
- No matches → `No matches found for pattern '<pattern>' in <path>`

---

## Security Model

### Sandboxing

All file operations are strictly sandboxed to `/workspace`:

```ruby
# ✅ Allowed
read_file(path: "notes.txt")           # → /workspace/notes.txt
read_file(path: "/workspace/data.txt") # → /workspace/data.txt
read_file(path: "data/file.txt")       # → /workspace/data/file.txt

# ❌ Denied (access outside workspace)
read_file(path: "../etc/passwd")       # → Error: Access denied
read_file(path: "/etc/passwd")         # → Error: Access denied
```

### Path Validation

Every path is validated and normalized:
1. Convert relative paths to absolute paths within `/workspace`
2. Resolve `.` and `..` components
3. Ensure final path starts with `/workspace/`
4. Reject if path escapes workspace boundary

### Permissions

- Read operations require file to be readable
- Write operations create files with standard permissions (644)
- Directory operations create directories with standard permissions (755)
- All operations run with the container's user context

---

## Deployment

### As a LanguageTool

```yaml
apiVersion: langop.io/v1alpha1
kind: LanguageTool
metadata:
  name: workspace
spec:
  image: ghcr.io/language-operator/workspace-tool:latest
  deploymentMode: service
  port: 80
  type: mcp
  volumes:
  - name: workspace
    mountPath: /workspace
    persistentVolumeClaim:
      claimName: agent-workspace
      readWriteMany: true
```

### Persistent Volume Setup

Create a PVC for shared workspace:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: agent-workspace
spec:
  accessModes:
  - ReadWriteMany
  resources:
    requests:
      storage: 10Gi
  storageClassName: nfs  # or your RWX-capable storage class
```

### Agent Configuration

```yaml
apiVersion: langop.io/v1alpha1
kind: LanguageAgent
metadata:
  name: my-agent
spec:
  instructions: |
    Use workspace to remember state between executions
  tools:
  - workspace
  workspace:
    enabled: true
    size: 10Gi
```

---

## Usage Patterns

### Checkpoint Pattern

Save progress and resume from last checkpoint:

```ruby
# Agent workflow
step :check_last_run do
  tool "workspace.read_file"
  params path: "checkpoint.json"

  on_success { |data|
    @last_checkpoint = JSON.parse(data)
    @resume_from = @last_checkpoint["last_id"]
  }

  on_error { @resume_from = 0 }
end

step :process_items do
  # Process items starting from @resume_from
  # ...
end

step :save_checkpoint do
  tool "workspace.write_file"
  params path: "checkpoint.json",
         content: { last_id: @current_id, timestamp: Time.now }.to_json
end
```

### State Machine Pattern

Track agent state across executions:

```ruby
step :load_state do
  tool "workspace.read_file"
  params path: "state.txt"
  on_error { "initialized" }
end

step :transition_state do
  case @current_state
  when "initialized"
    # First run logic
    @next_state = "running"
  when "running"
    # Ongoing logic
    @next_state = "running"
  when "completed"
    @next_state = "archived"
  end
end

step :save_state do
  tool "workspace.write_file"
  params path: "state.txt", content: @next_state
end
```

### Incremental Processing Pattern

Process only new data:

```ruby
step :get_last_processed do
  tool "workspace.read_file"
  params path: "last_processed.txt"
  on_success { |timestamp| @since = timestamp }
  on_error { @since = "1970-01-01" }
end

step :fetch_new_data do
  # Fetch data since @since timestamp
  # ...
end

step :update_timestamp do
  tool "workspace.write_file"
  params path: "last_processed.txt",
         content: Time.now.iso8601
end
```

### Knowledge Base Pattern

Build and query accumulated knowledge:

```ruby
step :append_to_knowledge do
  # Read existing knowledge
  tool "workspace.read_file"
  params path: "knowledge/facts.txt"
  on_success { |content| @knowledge = content }
  on_error { @knowledge = "" }

  # Append new fact
  @knowledge += "\n#{@new_fact}"

  # Write back
  tool "workspace.write_file"
  params path: "knowledge/facts.txt", content: @knowledge
end

step :query_knowledge do
  tool "workspace.search_files"
  params path: "knowledge", pattern: "**/*.txt"

  # Read and analyze matching files
end
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
      "name": "workspace-tool",
      "version": "1.0.0"
    },
    "capabilities": {
      "tools": {}
    }
  }
}
```

### List Tools

```json
POST /mcp
{
  "jsonrpc": "2.0",
  "id": 2,
  "method": "tools/list",
  "params": {}
}
```

### Call Tool

```json
POST /mcp
{
  "jsonrpc": "2.0",
  "id": 3,
  "method": "tools/call",
  "params": {
    "name": "read_file",
    "arguments": {
      "path": "notes.txt"
    }
  }
}
```

---

## Health Check

```bash
curl http://workspace.default.svc.cluster.local/health
```

Response:
```json
{
  "status": "ok",
  "service": "workspace-tool",
  "version": "1.0.0"
}
```

---

## Testing

### Manual Testing

```bash
# Initialize MCP session
curl -X POST http://localhost:8080/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}}'

# List available tools
curl -X POST http://localhost:8080/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}'

# Test read_file
curl -X POST http://localhost:8080/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"read_file","arguments":{"path":"README.md"}}}'

# Test list_directory
curl -X POST http://localhost:8080/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":4,"method":"tools/call","params":{"name":"list_directory","arguments":{"path":"."}}}'
```

### Automated Tests

```bash
# Run RSpec tests
cd workspace
bundle install
bundle exec rspec
```

---

## Troubleshooting

### Common Issues

**"Error: Access denied. Path must be within /workspace"**
- Cause: Attempting to access files outside `/workspace`
- Solution: Use relative paths or absolute paths within `/workspace`

**"Error: File not found"**
- Cause: File doesn't exist yet
- Solution: Check path with `list_directory` or create with `write_file`

**"Error: Invalid UTF-8 encoding"**
- Cause: File contains binary data or invalid UTF-8
- Solution: Workspace tool only supports UTF-8 text files

**"Error: Failed to create parent directory"**
- Cause: Permission issues or disk full
- Solution: Check PVC permissions and available storage

### Debug Mode

Enable debug logging:

```yaml
apiVersion: langop.io/v1alpha1
kind: LanguageTool
metadata:
  name: workspace
spec:
  image: ghcr.io/language-operator/workspace-tool:latest
  env:
  - name: LOG_LEVEL
    value: debug
```

---

## Performance Considerations

### File Size Limits

- No hard limit on file size
- Large files (>10MB) may cause memory pressure
- Use `head`/`tail` parameters for large files

### Search Performance

- `search_files` with recursive glob patterns can be slow on large directories
- Default limit of 100 results prevents excessive memory usage
- Consider organizing files in a shallow hierarchy

### Concurrency

- Multiple agents can read simultaneously
- Write operations are atomic but not transactional
- Use file-based locking if coordination is needed

---

## Best Practices

1. **Use relative paths**: `notes.txt` instead of `/workspace/notes.txt`
2. **Organize by date**: `logs/2025-11/app.log` for time-based data
3. **Use descriptive names**: `last_processed_timestamp.txt` instead of `state.txt`
4. **Clean up old files**: Implement retention policies in agent logic
5. **Handle missing files**: Always handle `read_file` errors gracefully
6. **Use JSON for structured data**: Easier to parse and validate
7. **Append vs overwrite**: Read + modify + write for append behavior

---

## Version

**Current Version:** 1.0.0

**MCP Protocol:** 2024-11-05

**Language Operator Compatibility:** v0.2.0+

---

## License

MIT License - see [LICENSE](../LICENSE)

---

## Related Documentation

- [Language Operator README](../../language-operator/README.md)
- [MCP Specification](https://modelcontextprotocol.io/)
- [LanguageTool CRD Reference](../../language-operator/docs/crds/languagetool.md)
- [Agent Patterns Guide](../../language-operator/docs/patterns.md)
