# Shell Command Tool

This tool provides secure shell command execution capabilities for Language Operator agents using the shell-mcp-server with safety restrictions and timeout controls.

## Overview

The Shell tool enables agents to execute bash commands in a controlled environment with directory restrictions, timeout protection, and comprehensive security measures to prevent system damage.

## Features

- **Secure command execution**: Restricted to allowed directories only
- **Timeout protection**: Automatic termination of long-running commands (30s default)
- **Directory isolation**: Commands restricted to `/workspace` and `/tmp`
- **Cross-platform support**: Bash shell execution in containerized environment
- **Common tools included**: curl, wget, git, jq pre-installed
- **Path validation**: Prevents access to system directories
- **Permission isolation**: Runs with limited container privileges

## MCP Tools

The shell-mcp-server provides tools for secure command execution (exact tool names depend on server implementation):

### `execute_command`

Execute shell commands safely within allowed directories.

**Parameters:**
- `command` (string, required): The bash command to execute
- `cwd` (string, optional): Working directory (must be within allowed paths)
- `timeout` (number, optional): Command timeout in seconds

**Security Restrictions:**
- Only `/workspace` and `/tmp` directories accessible
- 30-second default timeout
- No access to system directories
- Container-level permission isolation

**Returns:**
- Command output (stdout/stderr)
- Exit status
- Execution time

## Use Cases

Perfect for:
- **File operations**: Creating, moving, and processing files in workspace
- **Data processing**: Running scripts and transformations on data
- **Git operations**: Cloning repositories, making commits
- **Network requests**: Using curl/wget for API calls
- **Build processes**: Running compilation and packaging commands
- **System diagnostics**: Checking environment and resource usage

## Security Model

### Directory Restrictions
Commands are restricted to safe directories:
- `/workspace` - Shared workspace volume
- `/tmp` - Temporary file storage
- **Blocked**: `/`, `/etc`, `/usr`, `/bin`, `/home`, etc.

### Timeout Protection
- Default 30-second timeout prevents runaway processes
- Configurable via environment variable: `COMMAND_TIMEOUT`
- Automatic process termination on timeout

### Container Isolation
- Runs in isolated container environment
- No access to host system
- Limited container privileges
- No network access beyond egress rules

### Command Safety
- No shell injection vulnerabilities
- Direct process execution without shell interpretation
- Comprehensive error handling
- Audit logging of all commands

## Architecture

This tool wraps the shell-mcp-server:
- **Base Image**: Python 3.12 slim with shell-mcp-server
- **Deployment**: Sidecar mode with workspace volume
- **Protocol**: HTTP-based MCP server on port 80
- **Security**: Directory and timeout restrictions

## Environment Variables

- `ALLOWED_DIRECTORIES`: `/workspace,/tmp`
- `SHELL_TYPE`: `bash`
- `COMMAND_TIMEOUT`: `30` (seconds)

## Integration

Agents can use this tool to:

1. **File management**: Create, modify, and organize files
2. **Data processing**: Run scripts and utilities on data
3. **Git operations**: Version control and repository management
4. **Network operations**: API calls and data fetching
5. **Build automation**: Compilation and packaging workflows
6. **Environment inspection**: Check system status and resources

**Example Commands:**
```bash
# File operations
ls -la /workspace
cp /workspace/input.txt /workspace/output.txt
find /workspace -name "*.json" | head -10

# Data processing
cat /workspace/data.csv | cut -d',' -f1 | sort | uniq
jq '.data[] | .name' /workspace/config.json

# Git operations
cd /workspace && git status
git add . && git commit -m "Update files"

# Network requests
curl -s https://api.example.com/data | jq '.'
wget -O /tmp/file.zip https://example.com/archive.zip
```

## Limitations

- **No system access**: Cannot modify host system
- **Directory restrictions**: Limited to workspace and temp directories
- **Timeout limits**: Long-running processes will be terminated
- **No privileged operations**: Cannot install packages or modify system
- **Container isolation**: No access to host network or filesystems

## Best Practices

1. **Use absolute paths**: Specify full paths within allowed directories
2. **Handle timeouts**: Design commands to complete within time limits
3. **Check exit codes**: Always verify command success
4. **Use workspace**: Store persistent files in `/workspace`
5. **Temporary files**: Use `/tmp` for scratch space
6. **Error handling**: Capture and handle command failures gracefully