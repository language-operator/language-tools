# Use the official MCP filesystem server image
FROM mcp/filesystem:latest

# The official image already has the MCP server built and configured
# We just need to ensure it runs with the correct workspace directory argument
# The original entrypoint is: ["node", "/app/dist/index.js"]
# We override it to specify /workspace as the allowed directory

ENTRYPOINT ["node", "/app/dist/index.js", "/workspace"]