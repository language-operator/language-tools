require 'k8s-ruby'
require 'yaml'
require 'json'

# Kubernetes tools for MCP

# Helper methods for k8s tools
module K8sHelpers
  # Get Kubernetes client
  # @return [K8s::Client] Kubernetes client instance
  def self.client
    @client ||= begin
      # Try in-cluster config first, fall back to kubeconfig
      if File.exist?('/var/run/secrets/kubernetes.io/serviceaccount/token')
        K8s::Client.in_cluster_config
      else
        K8s::Client.config(K8s::Config.load_file(File.expand_path('~/.kube/config')))
      end
    rescue StandardError => e
      raise "Failed to initialize Kubernetes client: #{e.message}"
    end
  end

  # Parse resource reference (kind/name or kind.group/name)
  # @param resource [String] Resource reference
  # @return [Hash] Parsed resource info
  def self.parse_resource(resource)
    parts = resource.split('/')
    return { error: "Invalid resource format. Use: kind/name or kind.group/name" } if parts.length < 2

    kind_parts = parts[0].split('.')
    name = parts[1..-1].join('/')

    {
      kind: kind_parts[0],
      group: kind_parts[1],
      name: name
    }
  end

  # Format resource for display
  # @param resource [K8s::Resource] Kubernetes resource
  # @return [String] Formatted resource
  def self.format_resource(resource)
    metadata = resource.metadata
    spec_keys = resource.respond_to?(:spec) ? resource.spec&.to_h&.keys : []
    status_keys = resource.respond_to?(:status) ? resource.status&.to_h&.keys : []

    info = []
    info << "Kind: #{resource.kind}"
    info << "Name: #{metadata.name}"
    info << "Namespace: #{metadata.namespace}" if metadata.namespace
    info << "Created: #{metadata.creationTimestamp}" if metadata.creationTimestamp
    info << "Labels: #{metadata.labels.to_h}" if metadata.labels && !metadata.labels.to_h.empty?
    info << "Annotations: #{metadata.annotations.to_h}" if metadata.annotations && !metadata.annotations.to_h.empty?
    info << "Spec keys: #{spec_keys.join(', ')}" if spec_keys.any?
    info << "Status keys: #{status_keys.join(', ')}" if status_keys.any?

    info.join("\n")
  end

  # Format list of resources
  # @param resources [Array<K8s::Resource>] List of resources
  # @return [String] Formatted list
  def self.format_list(resources)
    return "No resources found" if resources.empty?

    lines = resources.map do |resource|
      name = resource.metadata.name
      namespace = resource.metadata.namespace
      age = resource.metadata.creationTimestamp ? Time.now - Time.parse(resource.metadata.creationTimestamp.to_s) : nil
      age_str = age ? "#{(age / 86400).to_i}d" : "unknown"

      if namespace
        "#{name} (namespace: #{namespace}, age: #{age_str})"
      else
        "#{name} (age: #{age_str})"
      end
    end

    lines.join("\n")
  end

  # Validate namespace
  # @param namespace [String, nil] Namespace
  # @return [String, nil] Namespace or nil for cluster-scoped
  def self.validate_namespace(namespace)
    return nil if namespace.nil? || namespace.empty? || namespace == "cluster"
    namespace
  end
end

# Get Kubernetes resource
tool "k8s_get" do
  description "Get a specific Kubernetes resource by name"

  parameter "resource" do
    type :string
    required true
    description "Resource type (e.g., 'pod', 'deployment', 'service')"
  end

  parameter "name" do
    type :string
    required true
    description "Resource name"
  end

  parameter "namespace" do
    type :string
    required false
    description "Namespace (omit for cluster-scoped resources or current namespace)"
  end

  parameter "output" do
    type :string
    required false
    description "Output format: 'summary' or 'yaml' (default: summary)"
    default "summary"
  end

  execute do |params|
    begin
      client = K8sHelpers.client
      namespace = K8sHelpers.validate_namespace(params['namespace'])

      # Get the API resource
      api_client = if namespace
        client.api(params['resource']).resource(params['resource'], namespace: namespace)
      else
        client.api(params['resource']).resource(params['resource'])
      end

      resource = api_client.get(params['name'])

      if params['output'] == 'yaml'
        YAML.dump(resource.to_h)
      else
        K8sHelpers.format_resource(resource)
      end
    rescue K8s::Error::NotFound
      "Error: Resource not found - #{params['resource']}/#{params['name']}"
    rescue K8s::Error::Forbidden
      "Error: Access denied - check RBAC permissions"
    rescue StandardError => e
      "Error: #{e.message}"
    end
  end
end

# List Kubernetes resources
tool "k8s_list" do
  description "List Kubernetes resources with optional label selector"

  parameter "resource" do
    type :string
    required true
    description "Resource type (e.g., 'pods', 'deployments', 'services')"
  end

  parameter "namespace" do
    type :string
    required false
    description "Namespace (omit for all namespaces or cluster-scoped resources)"
  end

  parameter "selector" do
    type :string
    required false
    description "Label selector (e.g., 'app=nginx,env=prod')"
  end

  parameter "limit" do
    type :number
    required false
    description "Maximum number of resources to return (default: 50)"
    default 50
  end

  execute do |params|
    begin
      client = K8sHelpers.client
      namespace = K8sHelpers.validate_namespace(params['namespace'])

      # Build options
      options = {}
      options[:labelSelector] = params['selector'] if params['selector']
      options[:limit] = params['limit'] || 50

      # Get the API resource
      api_client = if namespace
        client.api(params['resource']).resource(params['resource'], namespace: namespace)
      else
        client.api(params['resource']).resource(params['resource'])
      end

      list = api_client.list(**options)
      resources = list.resource

      header = if namespace
        "#{params['resource']} in namespace '#{namespace}'"
      else
        "#{params['resource']} (all namespaces)"
      end
      header += " with selector '#{params['selector']}'" if params['selector']

      "#{header}:\n\n#{K8sHelpers.format_list(resources)}"
    rescue K8s::Error::Forbidden
      "Error: Access denied - check RBAC permissions"
    rescue StandardError => e
      "Error: #{e.message}"
    end
  end
end

# Apply Kubernetes resource
tool "k8s_apply" do
  description "Create or update a Kubernetes resource from YAML"

  parameter "yaml" do
    type :string
    required true
    description "Resource YAML manifest"
  end

  parameter "namespace" do
    type :string
    required false
    description "Override namespace in manifest (optional)"
  end

  execute do |params|
    begin
      client = K8sHelpers.client

      # Parse YAML
      resource_hash = YAML.safe_load(params['yaml'], permitted_classes: [Symbol, Date, Time])

      # Override namespace if provided
      if params['namespace']
        resource_hash['metadata'] ||= {}
        resource_hash['metadata']['namespace'] = params['namespace']
      end

      # Create resource object
      resource = K8s::Resource.new(resource_hash)

      # Determine namespace
      namespace = resource.metadata&.namespace

      # Get the API client
      api_client = if namespace
        client.api(resource.apiVersion).resource(resource.kind, namespace: namespace)
      else
        client.api(resource.apiVersion).resource(resource.kind)
      end

      # Try to get existing resource
      existing = begin
        api_client.get(resource.metadata.name)
      rescue K8s::Error::NotFound
        nil
      end

      if existing
        # Update existing resource
        updated = api_client.update_resource(resource)
        "Successfully updated #{resource.kind}/#{resource.metadata.name}"
      else
        # Create new resource
        created = api_client.create_resource(resource)
        "Successfully created #{resource.kind}/#{resource.metadata.name}"
      end
    rescue K8s::Error::Forbidden
      "Error: Access denied - check RBAC permissions"
    rescue Psych::SyntaxError => e
      "Error: Invalid YAML - #{e.message}"
    rescue StandardError => e
      "Error: #{e.message}"
    end
  end
end

# Delete Kubernetes resource
tool "k8s_delete" do
  description "Delete a Kubernetes resource"

  parameter "resource" do
    type :string
    required true
    description "Resource type (e.g., 'pod', 'deployment', 'service')"
  end

  parameter "name" do
    type :string
    required true
    description "Resource name"
  end

  parameter "namespace" do
    type :string
    required false
    description "Namespace (omit for cluster-scoped resources)"
  end

  execute do |params|
    begin
      client = K8sHelpers.client
      namespace = K8sHelpers.validate_namespace(params['namespace'])

      # Get the API resource
      api_client = if namespace
        client.api(params['resource']).resource(params['resource'], namespace: namespace)
      else
        client.api(params['resource']).resource(params['resource'])
      end

      api_client.delete(params['name'])

      "Successfully deleted #{params['resource']}/#{params['name']}"
    rescue K8s::Error::NotFound
      "Error: Resource not found - #{params['resource']}/#{params['name']}"
    rescue K8s::Error::Forbidden
      "Error: Access denied - check RBAC permissions"
    rescue StandardError => e
      "Error: #{e.message}"
    end
  end
end

# Get pod logs
tool "k8s_logs" do
  description "Get logs from a pod"

  parameter "name" do
    type :string
    required true
    description "Pod name"
  end

  parameter "namespace" do
    type :string
    required false
    description "Namespace (defaults to 'default')"
  end

  parameter "container" do
    type :string
    required false
    description "Container name (required for multi-container pods)"
  end

  parameter "tail" do
    type :number
    required false
    description "Number of lines to show from end of logs (default: 100)"
    default 100
  end

  parameter "previous" do
    type :boolean
    required false
    description "Get logs from previous container instance (default: false)"
    default false
  end

  execute do |params|
    begin
      client = K8sHelpers.client
      namespace = K8sHelpers.validate_namespace(params['namespace']) || 'default'

      # Build log options
      options = {}
      options[:container] = params['container'] if params['container']
      options[:tailLines] = params['tail'] || 100
      options[:previous] = params['previous'] || false

      api_client = client.api('v1').resource('pods', namespace: namespace)
      logs = api_client.get(params['name']).logs(**options)

      header = "Logs for pod #{params['name']}"
      header += " (container: #{params['container']})" if params['container']
      header += " (previous instance)" if params['previous']

      "#{header}:\n\n#{logs}"
    rescue K8s::Error::NotFound
      "Error: Pod not found - #{params['name']}"
    rescue K8s::Error::BadRequest => e
      if e.message.include?('container')
        # Get pod to list containers
        begin
          api_client = client.api('v1').resource('pods', namespace: namespace || 'default')
          pod = api_client.get(params['name'])
          containers = pod.spec.containers.map(&:name)
          "Error: Multi-container pod. Please specify container name. Available: #{containers.join(', ')}"
        rescue
          "Error: #{e.message}"
        end
      else
        "Error: #{e.message}"
      end
    rescue K8s::Error::Forbidden
      "Error: Access denied - check RBAC permissions"
    rescue StandardError => e
      "Error: #{e.message}"
    end
  end
end

# Execute command in pod
tool "k8s_exec" do
  description "Execute a command in a pod container"

  parameter "name" do
    type :string
    required true
    description "Pod name"
  end

  parameter "command" do
    type :string
    required true
    description "Command to execute (e.g., 'ls -la', 'env')"
  end

  parameter "namespace" do
    type :string
    required false
    description "Namespace (defaults to 'default')"
  end

  parameter "container" do
    type :string
    required false
    description "Container name (required for multi-container pods)"
  end

  execute do |params|
    begin
      client = K8sHelpers.client
      namespace = K8sHelpers.validate_namespace(params['namespace']) || 'default'

      # Split command into array
      command_array = params['command'].split(' ')

      # Build exec options
      options = {
        command: command_array,
        stdout: true,
        stderr: true
      }
      options[:container] = params['container'] if params['container']

      api_client = client.api('v1').resource('pods', namespace: namespace)
      result = api_client.get(params['name']).exec(**options)

      header = "Command output from pod #{params['name']}"
      header += " (container: #{params['container']})" if params['container']

      "#{header}:\n\n#{result}"
    rescue K8s::Error::NotFound
      "Error: Pod not found - #{params['name']}"
    rescue K8s::Error::BadRequest => e
      if e.message.include?('container')
        # Get pod to list containers
        begin
          api_client = client.api('v1').resource('pods', namespace: namespace || 'default')
          pod = api_client.get(params['name'])
          containers = pod.spec.containers.map(&:name)
          "Error: Multi-container pod. Please specify container name. Available: #{containers.join(', ')}"
        rescue
          "Error: #{e.message}"
        end
      else
        "Error: #{e.message}"
      end
    rescue K8s::Error::Forbidden
      "Error: Access denied - check RBAC permissions"
    rescue StandardError => e
      "Error: #{e.message}"
    end
  end
end
