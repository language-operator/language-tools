FROM python:3.12-slim

# Install shell-mcp-server
RUN pip install shell-mcp-server

# Create working directory
WORKDIR /app

# Expose port 80 for Language Operator compatibility
EXPOSE 80

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

# Override entrypoint to run on port 80 with HTTP transport
ENTRYPOINT ["python", "-m", "shell_mcp_server", "--transport", "http", "--port", "80"]