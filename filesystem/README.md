# MCP Filesystem Reference Tool

This tool wraps the official [MCP filesystem server](https://github.com/modelcontextprotocol/servers/tree/main/src/filesystem) to provide advanced file operations within the Language Operator environment.

## Features

Advanced capabilities beyond the basic workspace tool:

- **Advanced File Editing**: `edit_file` with git-style diff preview, multi-line matching, and whitespace preservation
- **Media File Support**: Read images and audio files with base64 encoding and MIME type detection
- **Multiple File Operations**: Read multiple files simultaneously with `read_multiple_files`
- **Enhanced Directory Listing**: `list_directory_with_sizes` with sorting and size information
- **Directory Trees**: Recursive JSON tree structure with `directory_tree`
- **Comprehensive Search**: File search with exclude patterns
- **Tool Annotations**: Proper read-only/idempotent/destructive hints for clients

## Tools Available

| Tool | Description | Read-Only | Idempotent | Destructive |
|------|-------------|-----------|------------|-------------|
| `read_text_file` | Read complete file contents | ✓ | - | - |
| `read_media_file` | Read images/audio as base64 | ✓ | - | - |
| `read_multiple_files` | Read multiple files at once | ✓ | - | - |
| `write_file` | Create/overwrite files | ✗ | ✓ | ✓ |
| `edit_file` | Advanced file editing with diffs | ✗ | ✗ | ✓ |
| `create_directory` | Create directories | ✗ | ✓ | ✗ |
| `list_directory` | Basic directory listing | ✓ | - | - |
| `list_directory_with_sizes` | Directory listing with sizes | ✓ | - | - |
| `directory_tree` | Recursive JSON tree | ✓ | - | - |
| `move_file` | Move/rename files | ✗ | ✗ | ✗ |
| `search_files` | Search with glob patterns | ✓ | - | - |
| `get_file_info` | File metadata | ✓ | - | - |
| `list_allowed_directories` | Show accessible directories | ✓ | - | - |

## Deployment

The tool is deployed as a **sidecar** with shared workspace volume:

```yaml
deploymentMode: sidecar
volumes:
  - name: workspace
    mountPath: /workspace
```

All file operations are restricted to the `/workspace` directory for security.

## Comparison with Ruby Workspace Tool

This MCP reference implementation provides significant advantages:

1. **17 vs 6 tools** - Much broader functionality
2. **Advanced editing** - Diff preview, pattern matching, multi-line support
3. **Media support** - Binary files, images, audio with proper encoding
4. **Better UX** - Tool annotations help clients understand operation safety
5. **Official implementation** - Maintained by MCP team with latest features

## Building

```bash
make build
```

This will copy the MCP filesystem source and build a Docker image with the server configured for workspace access.