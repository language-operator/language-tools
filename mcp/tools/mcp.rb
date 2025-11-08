require 'k8s-ruby'
require 'faraday'
require 'json'
require 'uri'

# MCP Bridge tools for connecting to external MCP servers

# Helper methods for MCP tools
module MCPHelpers
  # Default timeout for MCP requests
  DEFAULT_TIMEOUT = 30

  # Get Kubernetes client for CRD discovery
  # @return [K8s::Client] Kubernetes client instance
  def self.k8s_client
    @k8s_client ||= begin
      if File.exist?('/var/run/secrets/kubernetes.io/serviceaccount/token')
        K8s::Client.in_cluster_config
      else
        K8s::Client.config(K8s::Config.load_file(File.expand_path('~/.kube/config')))
      end
    rescue StandardError => e
      raise "Failed to initialize Kubernetes client: #{e.message}"
    end
  end

  # Discover MCP servers from LanguageTool CRDs
  # @return [Array<Hash>] List of MCP servers with name, namespace, endpoint
  def self.discover_servers
    client = k8s_client

    # Get all LanguageTool resources across all namespaces
    api = client.api('langop.io/v1alpha1')
    resources = api.resource('languagetools')

    language_tools = resources.list

    # Filter for MCP type tools and build server list
    mcp_servers = language_tools.select do |tool|
      tool.spec&.type == 'mcp'
    end.map do |tool|
      {
        name: tool.metadata.name,
        namespace: tool.metadata.namespace,
        endpoint: build_endpoint(tool),
        display_name: tool.spec&.displayName || tool.metadata.name,
        description: tool.spec&.description || "MCP server"
      }
    end

    mcp_servers
  rescue K8s::Error::NotFound
    []
  rescue StandardError => e
    raise "Failed to discover MCP servers: #{e.message}"
  end

  # Build endpoint URL from LanguageTool resource
  # @param tool [K8s::Resource] LanguageTool resource
  # @return [String] Full HTTP endpoint URL
  def self.build_endpoint(tool)
    name = tool.metadata.name
    namespace = tool.metadata.namespace
    port = tool.spec&.port || 80

    # Build Kubernetes service DNS name
    "http://#{name}.#{namespace}.svc.cluster.local:#{port}/mcp"
  end

  # Get MCP server info by name
  # @param server_name [String] Server name to find
  # @return [Hash, nil] Server info or nil if not found
  def self.find_server(server_name)
    servers = discover_servers
    servers.find { |s| s[:name] == server_name }
  end

  # Initialize MCP connection to a server
  # @param endpoint [String] MCP server endpoint URL
  # @return [Hash] Server info from initialize response
  def self.initialize_connection(endpoint)
    conn = Faraday.new(url: endpoint) do |f|
      f.request :json
      f.response :json
      f.adapter Faraday.default_adapter
      f.options.timeout = DEFAULT_TIMEOUT
    end

    request = {
      jsonrpc: "2.0",
      id: 1,
      method: "initialize",
      params: {
        protocolVersion: "2024-11-05",
        capabilities: {},
        clientInfo: {
          name: "mcp-tool",
          version: "1.0.0"
        }
      }
    }

    response = conn.post do |req|
      req.body = request
    end

    if response.status != 200
      raise "HTTP #{response.status}: Failed to initialize MCP connection"
    end

    result = response.body
    if result['error']
      raise "MCP Error #{result['error']['code']}: #{result['error']['message']}"
    end

    result['result']
  rescue Faraday::Error => e
    raise "Connection error: #{e.message}"
  end

  # List tools from an MCP server
  # @param endpoint [String] MCP server endpoint URL
  # @return [Array<Hash>] List of tools
  def self.list_tools(endpoint)
    conn = Faraday.new(url: endpoint) do |f|
      f.request :json
      f.response :json
      f.adapter Faraday.default_adapter
      f.options.timeout = DEFAULT_TIMEOUT
    end

    # First initialize the connection
    initialize_connection(endpoint)

    # Then list tools
    request = {
      jsonrpc: "2.0",
      id: 2,
      method: "tools/list",
      params: {}
    }

    response = conn.post do |req|
      req.body = request
    end

    if response.status != 200
      raise "HTTP #{response.status}: Failed to list tools"
    end

    result = response.body
    if result['error']
      raise "MCP Error #{result['error']['code']}: #{result['error']['message']}"
    end

    result['result']['tools'] || []
  rescue Faraday::Error => e
    raise "Connection error: #{e.message}"
  end

  # Call a tool on an MCP server
  # @param endpoint [String] MCP server endpoint URL
  # @param tool_name [String] Name of the tool to call
  # @param arguments [Hash] Tool arguments
  # @return [Hash] Tool execution result
  def self.call_tool(endpoint, tool_name, arguments = {})
    conn = Faraday.new(url: endpoint) do |f|
      f.request :json
      f.response :json
      f.adapter Faraday.default_adapter
      f.options.timeout = DEFAULT_TIMEOUT
    end

    # First initialize the connection
    initialize_connection(endpoint)

    # Then call the tool
    request = {
      jsonrpc: "2.0",
      id: 3,
      method: "tools/call",
      params: {
        name: tool_name,
        arguments: arguments || {}
      }
    }

    response = conn.post do |req|
      req.body = request
    end

    if response.status != 200
      raise "HTTP #{response.status}: Failed to call tool"
    end

    result = response.body
    if result['error']
      raise "MCP Error #{result['error']['code']}: #{result['error']['message']}"
    end

    result['result']
  rescue Faraday::Error => e
    raise "Connection error: #{e.message}"
  end

  # Format server list for display
  # @param servers [Array<Hash>] List of servers
  # @return [String] Formatted server list
  def self.format_server_list(servers)
    return "No MCP servers found in cluster" if servers.empty?

    lines = ["Found #{servers.length} MCP server(s):", ""]
    servers.each do |server|
      lines << "• #{server[:name]}"
      lines << "  Display Name: #{server[:display_name]}"
      lines << "  Description: #{server[:description]}"
      lines << "  Namespace: #{server[:namespace]}"
      lines << "  Endpoint: #{server[:endpoint]}"
      lines << ""
    end

    lines.join("\n")
  end

  # Format tool list for display
  # @param tools [Array<Hash>] List of tools
  # @return [String] Formatted tool list
  def self.format_tool_list(tools)
    return "No tools available on this server" if tools.empty?

    lines = ["Found #{tools.length} tool(s):", ""]
    tools.each do |tool|
      lines << "• #{tool['name']}"
      lines << "  Description: #{tool['description']}" if tool['description']
      if tool['inputSchema'] && tool['inputSchema']['properties']
        params = tool['inputSchema']['properties'].keys
        lines << "  Parameters: #{params.join(', ')}" unless params.empty?
      end
      lines << ""
    end

    lines.join("\n")
  end

  # Format server info for display
  # @param info [Hash] Server info from initialize
  # @return [String] Formatted server info
  def self.format_server_info(info)
    lines = []

    if info['serverInfo']
      server_info = info['serverInfo']
      lines << "Server Information:"
      lines << "  Name: #{server_info['name']}"
      lines << "  Version: #{server_info['version']}" if server_info['version']
      lines << ""
    end

    if info['protocolVersion']
      lines << "Protocol Version: #{info['protocolVersion']}"
      lines << ""
    end

    if info['capabilities']
      caps = info['capabilities']
      lines << "Capabilities:"
      lines << "  Tools: #{caps['tools'] ? 'supported' : 'not supported'}"
      lines << "  Resources: #{caps['resources'] ? 'supported' : 'not supported'}"
      lines << "  Prompts: #{caps['prompts'] ? 'supported' : 'not supported'}"
      lines << ""
    end

    lines.join("\n")
  end
end

# Discover MCP servers available in the cluster
tool "mcp_discover" do
  description "Discover MCP servers available in the Kubernetes cluster via LanguageTool CRDs"

  execute do |params|
    begin
      servers = MCPHelpers.discover_servers
      MCPHelpers.format_server_list(servers)
    rescue K8s::Error::Forbidden
      "Error: Access denied - check RBAC permissions for LanguageTool CRDs"
    rescue StandardError => e
      "Error: #{e.message}"
    end
  end
end

# List tools from an MCP server
tool "mcp_list_tools" do
  description "List all tools exposed by a specific MCP server"

  parameter "server" do
    type :string
    required true
    description "Name of the MCP server (from mcp_discover)"
  end

  execute do |params|
    begin
      server_info = MCPHelpers.find_server(params['server'])

      if server_info.nil?
        return "Error: Server '#{params['server']}' not found. Use mcp_discover to see available servers."
      end

      tools = MCPHelpers.list_tools(server_info[:endpoint])

      header = "Tools from #{server_info[:display_name]}:\n\n"
      header + MCPHelpers.format_tool_list(tools)
    rescue StandardError => e
      "Error: #{e.message}"
    end
  end
end

# Call a tool on an MCP server
tool "mcp_call" do
  description "Call a tool from any registered MCP server with specified arguments"

  parameter "server" do
    type :string
    required true
    description "Name of the MCP server"
  end

  parameter "tool" do
    type :string
    required true
    description "Name of the tool to call"
  end

  parameter "arguments" do
    type :object
    required false
    description "Arguments to pass to the tool (as JSON object)"
  end

  execute do |params|
    begin
      server_info = MCPHelpers.find_server(params['server'])

      if server_info.nil?
        return "Error: Server '#{params['server']}' not found. Use mcp_discover to see available servers."
      end

      arguments = params['arguments'] || {}
      result = MCPHelpers.call_tool(server_info[:endpoint], params['tool'], arguments)

      # Format the result
      if result['content']
        # MCP returns content as array of content items
        content_items = result['content'].map do |item|
          case item['type']
          when 'text'
            item['text']
          when 'image'
            "[Image: #{item['mimeType']}]"
          when 'resource'
            "[Resource: #{item['uri']}]"
          else
            "[#{item['type']}]"
          end
        end
        content_items.join("\n")
      elsif result['error']
        "Tool Error: #{result['error']}"
      else
        # Fallback to JSON representation
        JSON.pretty_generate(result)
      end
    rescue StandardError => e
      "Error: #{e.message}"
    end
  end
end

# Get MCP server information and capabilities
tool "mcp_server_info" do
  description "Get detailed information about an MCP server including capabilities and metadata"

  parameter "server" do
    type :string
    required true
    description "Name of the MCP server"
  end

  execute do |params|
    begin
      server_info = MCPHelpers.find_server(params['server'])

      if server_info.nil?
        return "Error: Server '#{params['server']}' not found. Use mcp_discover to see available servers."
      end

      initialize_result = MCPHelpers.initialize_connection(server_info[:endpoint])

      header = "Server: #{server_info[:display_name]}\n"
      header += "Description: #{server_info[:description]}\n"
      header += "Endpoint: #{server_info[:endpoint]}\n\n"

      header + MCPHelpers.format_server_info(initialize_result)
    rescue StandardError => e
      "Error: #{e.message}"
    end
  end
end
