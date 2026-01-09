FROM python:3.12-slim

# Install shell-mcp-server
RUN pip install shell-mcp-server

# Copy HTTP bridge (uses Python standard library only)
COPY http-bridge.py /app/http-bridge.py
RUN chmod +x /app/http-bridge.py

# Create working directory
WORKDIR /app

# Set environment variables for security
ENV ALLOWED_DIRECTORIES="/workspace,/tmp"
ENV SHELL_TYPE="bash"
ENV COMMAND_TIMEOUT="30"

# Install common tools that agents might need
RUN apt-get update && apt-get install -y \
    bash \
    curl \
    wget \
    git \
    jq \
    && rm -rf /var/lib/apt/lists/*

# Expose port 80 for Language Operator compatibility
EXPOSE 80

# Run HTTP bridge that wraps the stdio MCP server
ENTRYPOINT ["python3", "/app/http-bridge.py"]