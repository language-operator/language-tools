#!/usr/bin/env ruby
# frozen_string_literal: true

require 'yaml'
require 'pathname'

# Script to compile tool manifests into a unified index.yaml
# Usage: ruby scripts/compile-index.rb

class ManifestCompiler
  TOOL_DIRS = %w[email web k8s filesystem mcp].freeze
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
    TOOL_DIRS.each do |dir|
      manifest_path = File.join(dir, 'manifest.yaml')

      unless File.exist?(manifest_path)
        @errors << "Missing manifest.yaml in #{dir}/"
        next
      end

      begin
        manifest = YAML.load_file(manifest_path)
        tool_name = manifest['name']

        if tool_name.nil? || tool_name.empty?
          @errors << "Tool in #{dir}/ has no 'name' field in manifest.yaml"
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
    required_fields = %w[name displayName description image deploymentMode port type]

    @tools.each do |name, manifest|
      required_fields.each do |field|
        unless manifest.key?(field)
          @errors << "Tool '#{name}' missing required field: #{field}"
        end
      end

      # Validate deployment mode
      valid_modes = %w[service job]
      if manifest['deploymentMode'] && !valid_modes.include?(manifest['deploymentMode'])
        @errors << "Tool '#{name}' has invalid deploymentMode: #{manifest['deploymentMode']}"
      end

      # Validate type
      valid_types = %w[mcp stdio http]
      if manifest['type'] && !valid_types.include?(manifest['type'])
        @errors << "Tool '#{name}' has invalid type: #{manifest['type']}"
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
      # Add the main tool entry
      @index['tools'][name] = manifest.reject { |k| k == 'aliases' }

      # Add alias entries
      aliases = manifest['aliases'] || []
      aliases.each do |alias_name|
        @index['tools'][alias_name] = { 'alias' => name }
      end
    end
  end

  def write_output
    File.write(OUTPUT_FILE, @index.to_yaml)
  end
end

# Run the compiler
ManifestCompiler.new.compile
