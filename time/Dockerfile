FROM mcp/time:latest

# Install Python and aiohttp for HTTP bridge
RUN apt-get update && apt-get install -y python3 python3-pip && \
    pip3 install aiohttp && \
    rm -rf /var/lib/apt/lists/*

# Copy HTTP bridge
COPY http-bridge.py /app/http-bridge.py
RUN chmod +x /app/http-bridge.py

# Expose port 80 for Language Operator compatibility
EXPOSE 80

# Run HTTP bridge that wraps the stdio MCP server
ENTRYPOINT ["python3", "/app/http-bridge.py"]