#!/usr/bin/env ruby
# frozen_string_literal: true

require 'yaml'
require 'pathname'

# Script to compile tool manifests into a unified index.yaml
# Usage: ruby scripts/compile-index.rb
#
# This script parses LanguageTool CRD manifests and generates an index
# containing complete Kubernetes resources that can be:
# 1. Applied directly to Kubernetes via kubectl
# 2. Consumed by the dashboard without transformation
# 3. Validated against CRD OpenAPI schema

class ManifestCompiler
  OUTPUT_FILE = 'index.yaml'

  def initialize
    @tools = {}
    @errors = []
  end

  def compile
    puts "Compiling tool registry index..."

    discover_tools
    validate_manifests

    if @errors.any?
      puts "\nErrors found:"
      @errors.each { |error| puts "  - #{error}" }
      exit 1
    end

    generate_index
    write_output

    puts "\n✓ Successfully compiled #{@tools.size} tool(s) to #{OUTPUT_FILE}"
    puts "  Tools: #{@tools.keys.join(', ')}"
  end

  private

  def discover_tools
    # Auto-discover all directories containing manifest.yaml
    Dir.glob('*/manifest.yaml').sort.each do |manifest_path|
      dir = File.dirname(manifest_path)

      begin
        manifest = YAML.load_file(manifest_path)

        # Extract tool name from metadata.name (CRD format)
        tool_name = manifest.dig('metadata', 'name')

        if tool_name.nil? || tool_name.empty?
          @errors << "Tool in #{dir}/ has no 'metadata.name' field in manifest.yaml"
          next
        end

        if @tools.key?(tool_name)
          @errors << "Duplicate tool name '#{tool_name}' (found in #{dir}/)"
          next
        end

        @tools[tool_name] = manifest
        puts "  Found: #{tool_name} (#{dir}/)"
      rescue StandardError => e
        @errors << "Failed to parse #{manifest_path}: #{e.message}"
      end
    end
  end

  def validate_manifests
    @tools.each do |name, manifest|
      # Validate CRD structure
      unless manifest['apiVersion'] == 'langop.io/v1alpha1'
        @errors << "Tool '#{name}' has invalid or missing apiVersion (expected 'langop.io/v1alpha1')"
      end

      unless manifest['kind'] == 'LanguageTool'
        @errors << "Tool '#{name}' has invalid or missing kind (expected 'LanguageTool')"
      end

      # Validate metadata
      unless manifest['metadata']
        @errors << "Tool '#{name}' missing metadata section"
        next
      end

      # Validate spec section
      unless manifest['spec']
        @errors << "Tool '#{name}' missing spec section"
        next
      end

      spec = manifest['spec']
      required_fields = %w[description image deploymentMode port type]

      required_fields.each do |field|
        unless spec.key?(field)
          @errors << "Tool '#{name}' missing required spec field: #{field}"
        end
      end

      # Validate deployment mode
      valid_modes = %w[service job sidecar]
      if spec['deploymentMode'] && !valid_modes.include?(spec['deploymentMode'])
        @errors << "Tool '#{name}' has invalid deploymentMode: #{spec['deploymentMode']}"
      end

      # Validate type
      valid_types = %w[mcp stdio http]
      if spec['type'] && !valid_types.include?(spec['type'])
        @errors << "Tool '#{name}' has invalid type: #{spec['type']}"
      end

      # Validate egress format (if present)
      if spec['egress']
        spec['egress'].each_with_index do |rule, index|
          # Check if DNS is directly under the rule (old format - should fail)
          if rule['dns'] && !rule['to']
            @errors << "Tool '#{name}' egress rule ##{index} uses old format - 'dns' must be under 'to' wrapper"
          end

          # Validate new format structure
          if rule['to']
            unless rule['to'].is_a?(Hash)
              @errors << "Tool '#{name}' egress rule ##{index} 'to' must be an object"
            end
          end
        end
      end
    end
  end

  def generate_index
    @index = {
      'version' => '1.0',
      'generated' => Time.now.utc.iso8601,
      'tools' => {}
    }

    @tools.each do |name, manifest|
      # Store the complete LanguageTool CRD resource
      # This allows the index to be used directly with kubectl or consumed by dashboards
      @index['tools'][name] = manifest
    end
  end

  def write_output
    # Generate index with complete LanguageTool resources
    # The output can be split and applied to Kubernetes or consumed as-is
    yaml_content = @index.to_yaml
    File.write(OUTPUT_FILE, yaml_content)
  end
end

# Run the compiler
ManifestCompiler.new.compile
