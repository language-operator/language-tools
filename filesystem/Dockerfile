FROM mcp/filesystem:latest

# Install Python for HTTP bridge (Alpine uses apk)
RUN apk add --no-cache python3

# Copy HTTP bridge (uses Python standard library only)
COPY http-bridge.py /app/http-bridge.py
RUN chmod +x /app/http-bridge.py

# Expose port 80 for Language Operator compatibility
EXPOSE 80

# Run HTTP bridge that wraps the stdio MCP server
ENTRYPOINT ["python3", "/app/http-bridge.py"]