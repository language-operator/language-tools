FROM mcp/time:latest

# Expose port 80 for Language Operator compatibility
EXPOSE 80

# The time server only supports stdio transport, not HTTP
# Use default stdio transport - Language Operator should handle protocol bridging  
ENTRYPOINT ["mcp-server-time"]