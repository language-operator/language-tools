FROM mcp/time:latest

# Expose port 80 for Language Operator compatibility
EXPOSE 80

# Override entrypoint to run on port 80 with HTTP transport
ENTRYPOINT ["mcp-server-time", "--transport", "http", "--port", "80"]