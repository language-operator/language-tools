require 'fileutils'
require 'pathname'
require 'language_operator'

# Filesystem tools for MCP

# Helper methods for filesystem tools
module FilesystemHelpers
  # Workspace root directory - all operations must be within this directory
  WORKSPACE_ROOT = '/workspace'

  # Validate and normalize a path to ensure it's within workspace
  # @param path [String] Path to validate (relative or absolute)
  # @return [String] Absolute normalized path, or error message
  def self.validate_and_normalize_path(path)
    # Convert to string and strip whitespace
    path = path.to_s.strip

    # Reject empty paths
    return LanguageOperator::Errors.empty_field("Path") if path.empty?

    # Build absolute path
    # All paths are relative to workspace root
    absolute_path = if path.start_with?('/')
      # Treat leading slash as relative to workspace root
      File.join(WORKSPACE_ROOT, path)
    else
      # No leading slash - still relative to workspace root
      File.join(WORKSPACE_ROOT, path)
    end

    # Normalize the path (resolve .., ., etc.)
    normalized = File.expand_path(absolute_path)

    # Ensure the path is within workspace
    unless normalized.start_with?(WORKSPACE_ROOT + '/') || normalized == WORKSPACE_ROOT
      return "Error: Access denied. Path must be within #{WORKSPACE_ROOT}"
    end

    normalized
  rescue StandardError => e
    "Error: Invalid path - #{e.message}"
  end

  # Read file with optional head/tail limiting
  # @param path [String] File path
  # @param head [Integer, nil] Read only first N lines
  # @param tail [Integer, nil] Read only last N lines
  # @return [String] File contents or error message
  def self.safe_read(path, head: nil, tail: nil)
    unless File.exist?(path)
      return "Error: File not found: #{path}"
    end

    unless File.file?(path)
      return "Error: Not a file: #{path}"
    end

    unless File.readable?(path)
      return "Error: File not readable: #{path}"
    end

    content = File.read(path, encoding: 'UTF-8')

    # Apply head/tail if specified
    if head || tail
      lines = content.lines
      lines = lines.first(head) if head
      lines = lines.last(tail) if tail
      content = lines.join
    end

    content
  rescue Encoding::InvalidByteSequenceError, Encoding::UndefinedConversionError
    "Error: File contains invalid UTF-8 encoding"
  rescue StandardError => e
    "Error: Failed to read file - #{e.message}"
  end

  # Format file size in human-readable format
  # @param size [Integer] Size in bytes
  # @return [String] Formatted size
  def self.format_size(size)
    units = ['B', 'KB', 'MB', 'GB', 'TB']
    unit_index = 0
    size_float = size.to_f

    while size_float >= 1024 && unit_index < units.length - 1
      size_float /= 1024.0
      unit_index += 1
    end

    if unit_index == 0
      "#{size} #{units[unit_index]}"
    else
      "#{format('%.2f', size_float)} #{units[unit_index]}"
    end
  end

  # Get file type string
  # @param path [String] File path
  # @return [String] File type
  def self.file_type(path)
    if File.directory?(path)
      'directory'
    elsif File.file?(path)
      'file'
    elsif File.symlink?(path)
      'symlink'
    else
      'other'
    end
  end
end

# Read file tool
tool "read_file" do
  description "Read complete file contents from workspace"

  parameter "path" do
    type :string
    required true
    description "File path relative to workspace root. Use '/' for workspace root, 'file.txt' or '/file.txt' for files in root, 'subdir/file.txt' or '/subdir/file.txt' for nested paths. Leading slash is optional."
  end

  parameter "head" do
    type :number
    required false
    description "Read only first N lines"
  end

  parameter "tail" do
    type :number
    required false
    description "Read only last N lines"
  end

  execute do |params|
    # Cannot specify both head and tail
    if params['head'] && params['tail']
      next "Error: Cannot specify both 'head' and 'tail' parameters"
    end

    # Validate path
    validated_path = FilesystemHelpers.validate_and_normalize_path(params['path'])
    next validated_path if validated_path.start_with?('Error:')

    # Read file
    FilesystemHelpers.safe_read(
      validated_path,
      head: params['head']&.to_i,
      tail: params['tail']&.to_i
    )
  end
end

# Write file tool
tool "write_file" do
  description "Create new file or completely overwrite existing file in workspace. IMPORTANT: This replaces the entire file contents. To append to a file, first read the existing content, then write the combined content."

  parameter "path" do
    type :string
    required true
    description "File path relative to /workspace (or absolute path within /workspace). Example: 'story.txt' or 'data/notes.txt'"
  end

  parameter "content" do
    type :string
    required true
    description "Complete file contents to write (replaces any existing content). Can be multi-line text - use \\n for line breaks. Can be empty string for empty file. Example: 'Hello\\nWorld' for two lines of text."
  end

  execute do |params|
    # Validate path
    validated_path = FilesystemHelpers.validate_and_normalize_path(params['path'])
    next validated_path if validated_path.start_with?('Error:')

    # Ensure parent directory exists
    parent_dir = File.dirname(validated_path)
    unless File.directory?(parent_dir)
      begin
        FileUtils.mkdir_p(parent_dir)
      rescue StandardError => e
        next "Error: Failed to create parent directory - #{e.message}"
      end
    end

    # Write file
    begin
      File.write(validated_path, params['content'], encoding: 'UTF-8')
      "Successfully wrote #{params['content'].bytesize} bytes to #{params['path']}"
    rescue StandardError => e
      "Error: Failed to write file - #{e.message}"
    end
  end
end

# List directory tool
tool "list_directory" do
  description "List directory contents with [FILE] or [DIR] indicators"

  parameter "path" do
    type :string
    required true
    description "Directory path relative to /workspace (or absolute path within /workspace)"
  end

  execute do |params|
    # Validate path
    validated_path = FilesystemHelpers.validate_and_normalize_path(params['path'])
    next validated_path if validated_path.start_with?('Error:')

    unless File.exist?(validated_path)
      next "Error: Directory not found: #{params['path']}"
    end

    unless File.directory?(validated_path)
      next "Error: Not a directory: #{params['path']}"
    end

    begin
      entries = Dir.entries(validated_path).sort
      # Remove . and ..
      entries = entries.reject { |e| e == '.' || e == '..' }

      if entries.empty?
        "Directory is empty: #{params['path']}"
      else
        result = entries.map do |entry|
          full_path = File.join(validated_path, entry)
          indicator = File.directory?(full_path) ? '[DIR]' : '[FILE]'
          "#{indicator} #{entry}"
        end.join("\n")

        "Contents of #{params['path']}:\n\n#{result}"
      end
    rescue StandardError => e
      "Error: Failed to list directory - #{e.message}"
    end
  end
end

# Create directory tool
tool "create_directory" do
  description "Create new directory in workspace (creates parent directories as needed)"

  parameter "path" do
    type :string
    required true
    description "Directory path relative to /workspace (or absolute path within /workspace)"
  end

  execute do |params|
    # Validate path
    validated_path = FilesystemHelpers.validate_and_normalize_path(params['path'])
    next validated_path if validated_path.start_with?('Error:')

    # Check if already exists
    if File.exist?(validated_path)
      if File.directory?(validated_path)
        next "Directory already exists: #{params['path']}"
      else
        next "Error: Path exists but is not a directory: #{params['path']}"
      end
    end

    # Create directory with parents
    begin
      FileUtils.mkdir_p(validated_path)
      "Successfully created directory: #{params['path']}"
    rescue StandardError => e
      "Error: Failed to create directory - #{e.message}"
    end
  end
end

# Get file info tool
tool "get_file_info" do
  description "Get detailed file or directory metadata"

  parameter "path" do
    type :string
    required true
    description "File or directory path relative to /workspace (or absolute path within /workspace)"
  end

  execute do |params|
    # Validate path
    validated_path = FilesystemHelpers.validate_and_normalize_path(params['path'])
    next validated_path if validated_path.start_with?('Error:')

    unless File.exist?(validated_path)
      next "Error: Path not found: #{params['path']}"
    end

    begin
      stat = File.stat(validated_path)
      type = FilesystemHelpers.file_type(validated_path)

      info = []
      info << "Path: #{params['path']}"
      info << "Type: #{type}"
      info << "Size: #{FilesystemHelpers.format_size(stat.size)}" if type == 'file'
      info << "Permissions: #{format('%o', stat.mode & 0777)}"
      info << "Owner UID: #{stat.uid}"
      info << "Owner GID: #{stat.gid}"
      info << "Created: #{stat.ctime}"
      info << "Modified: #{stat.mtime}"
      info << "Accessed: #{stat.atime}"

      if type == 'directory'
        entry_count = Dir.entries(validated_path).count - 2 # Exclude . and ..
        info << "Entries: #{entry_count}"
      end

      info.join("\n")
    rescue StandardError => e
      "Error: Failed to get file info - #{e.message}"
    end
  end
end

# Search files tool
tool "search_files" do
  description "Recursively search for files and directories matching a glob pattern"

  parameter "path" do
    type :string
    required true
    description "Starting directory path relative to /workspace"
  end

  parameter "pattern" do
    type :string
    required true
    description "Glob pattern to match (e.g., '*.rb', '**/*.txt')"
  end

  parameter "max_results" do
    type :number
    required false
    description "Maximum number of results to return (default: 100)"
    default 100
  end

  execute do |params|
    # Validate path
    validated_path = FilesystemHelpers.validate_and_normalize_path(params['path'])
    next validated_path if validated_path.start_with?('Error:')

    unless File.exist?(validated_path)
      next "Error: Directory not found: #{params['path']}"
    end

    unless File.directory?(validated_path)
      next "Error: Not a directory: #{params['path']}"
    end

    pattern = params['pattern']
    max_results = (params['max_results'] || 100).to_i

    begin
      # Build search pattern
      search_pattern = File.join(validated_path, pattern)

      # Search for matches
      matches = Dir.glob(search_pattern).select do |path|
        # Ensure result is within workspace
        path.start_with?(FilesystemHelpers::WORKSPACE_ROOT)
      end

      # Sort and limit results
      matches = matches.sort.first(max_results)

      if matches.empty?
        "No matches found for pattern '#{pattern}' in #{params['path']}"
      else
        # Format results relative to workspace
        results = matches.map do |match|
          relative = match.sub("#{FilesystemHelpers::WORKSPACE_ROOT}/", '')
          indicator = File.directory?(match) ? '[DIR]' : '[FILE]'
          "#{indicator} #{relative}"
        end

        count_msg = matches.length == max_results ? " (limited to #{max_results})" : ""
        "Found #{matches.length} match(es)#{count_msg} for '#{pattern}':\n\n#{results.join("\n")}"
      end
    rescue StandardError => e
      "Error: Search failed - #{e.message}"
    end
  end
end
