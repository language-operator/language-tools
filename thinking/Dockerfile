FROM mcp/sequentialthinking:latest

# Expose port 80 for Language Operator compatibility
EXPOSE 80

# Override entrypoint to run on port 80 with HTTP transport
ENTRYPOINT ["node", "dist/index.js", "--transport", "http", "--port", "80"]