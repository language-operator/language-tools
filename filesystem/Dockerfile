FROM git.theryans.io/language-operator/base:latest

# Ensure we're running as root for installation
USER root

# Install Ruby and build dependencies
RUN apk add --no-cache \
    ruby \
    ruby-dev \
    ruby-bundler \
    build-base \
    ca-certificates

# Set up app directory for bundle install
WORKDIR /app

# Copy Gemfile and install dependencies
COPY Gemfile /app/

# Install gems (credentials inherited from base image)
RUN bundle install --no-cache

# Copy filesystem tools to /mcp
WORKDIR /mcp
COPY tools/ /mcp/

# Create /workspace directory for filesystem operations
RUN mkdir -p /workspace && chown -R langop:langop /workspace

# Ensure directories are owned by langop user
RUN chown -R langop:langop /mcp

# Switch to langop user
USER langop

# Expose default port
EXPOSE 80

# Set environment variables
ENV PORT=80
ENV RACK_ENV=production

# Start the MCP server
CMD ["ruby", "-r", "language_operator/tool_loader", "-e", "LanguageOperator::ToolLoader.start"]
