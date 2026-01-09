FROM mcp/memory:latest

# Expose port 80 for Language Operator compatibility
EXPOSE 80

# Set memory file path to workspace directory
ENV MEMORY_FILE_PATH="/workspace/.memory/memory.jsonl"

# Override entrypoint to run on port 80 with HTTP transport
ENTRYPOINT ["node", "dist/index.js", "--transport", "http", "--port", "80"]