# frozen_string_literal: true

# Web search and scraping tools for MCP

require 'json'
require 'uri'
require 'language_operator'

# Helper methods for web tools
module WebHelpers
  # Content truncation limit for text output
  CONTENT_TRUNCATION_LIMIT = 2000

  # HTML stripping patterns
  HTML_STRIP_PATTERNS = [
    %r{<script[^>]*>.*?</script>}im,
    %r{<style[^>]*>.*?</style>}im,
    /<[^>]+>/
  ].freeze

  # Common HTTP status codes
  HTTP_STATUS_CODES = {
    200 => 'OK',
    201 => 'Created',
    204 => 'No Content',
    301 => 'Moved Permanently',
    302 => 'Found (Redirect)',
    304 => 'Not Modified',
    400 => 'Bad Request',
    401 => 'Unauthorized',
    403 => 'Forbidden',
    404 => 'Not Found',
    422 => 'Unprocessable Entity',
    429 => 'Too Many Requests',
    500 => 'Internal Server Error',
    502 => 'Bad Gateway',
    503 => 'Service Unavailable',
    504 => 'Gateway Timeout'
  }.freeze

  # Strip HTML tags and normalize whitespace
  # @param content [String] HTML content
  # @return [String] Plain text content
  def self.strip_html_and_normalize(content)
    HTML_STRIP_PATTERNS.reduce(content) { |text, pattern| text.gsub(pattern, ' ') }
                       .gsub(/\s+/, ' ')
                       .strip
  end

  # Truncate content with ellipsis if needed
  # @param text [String] Text to truncate
  # @param limit [Integer] Maximum length
  # @return [String] Truncated text
  def self.truncate_content(text, limit = CONTENT_TRUNCATION_LIMIT)
    text.length > limit ? "#{text[0...limit]}..." : text
  end

  # Get status code description
  # @param status [Integer] HTTP status code
  # @return [String] Status description
  def self.status_description(status)
    HTTP_STATUS_CODES.fetch(status, 'Unknown')
  end

  # Parse JSON safely
  # @param text [String] JSON text
  # @return [Hash, Array, nil] Parsed JSON or nil if invalid
  def self.parse_json(text)
    JSON.parse(text)
  rescue JSON::ParserError
    nil
  end

  # Build query string from params
  # @param params [Hash] Query parameters
  # @return [String] Query string
  def self.build_query_string(params)
    return '' if params.nil? || params.empty?

    "?#{URI.encode_www_form(params)}"
  end
end

tool 'web_search' do
  description 'Search the web using DuckDuckGo and return results'

  parameter 'query' do
    type :string
    required true
    description 'The search query'
  end

  parameter 'max_results' do
    type :number
    required false
    description 'Maximum number of results to return (default: 5)'
    default 5
  end

  execute do |params|
    query = params['query']
    max_results = (params['max_results'] || 5).to_i

    # URL encode the query
    encoded_query = URI.encode_www_form_component(query)

    # Use DuckDuckGo HTML interface
    url = "https://html.duckduckgo.com/html/?q=#{encoded_query}"

    # Fetch results using SDK HTTP client
    response = LanguageOperator::Dsl::HTTP.get(url, headers: { 'User-Agent' => 'Mozilla/5.0' }, follow_redirects: true)

    next "Error: Failed to fetch search results - #{response[:error] || response[:status]}" unless response[:success]

    html = response[:body]

    # Parse results (simple text extraction)
    results = []

    # Extract result blocks using simple pattern matching
    html.scan(%r{<a[^>]+class="[^"]*result__a[^"]*"[^>]+href="([^"]+)"[^>]*>([^<]+)</a>}i).each_with_index do |(href, title), index|
      break if index >= max_results

      # Clean up the URL (DuckDuckGo redirects)
      clean_url = href.gsub(%r{^//duckduckgo\.com/l/\?.*uddg=}, '')
      clean_url = URI.decode_www_form_component(clean_url) if clean_url.include?('%')

      results << "#{index + 1}. #{title.strip}\n   URL: #{clean_url}"
    end

    if results.empty?
      "No results found for: #{query}"
    else
      "Search results for: #{query}\n\n" + results.join("\n\n")
    end
  end
end

tool 'web_fetch' do
  description 'Fetch and extract text content from a URL'

  parameter 'url' do
    type :string
    required true
    description 'The URL to fetch'
  end

  parameter 'html' do
    type :boolean
    required false
    description 'Return raw HTML instead of text (default: false)'
    default false
  end

  execute do |params|
    url = params['url']
    return_html = params['html'] || false

    # Validate URL
    error = LanguageOperator::Validators.http_url(url)
    next error if error

    # Fetch the URL using SDK HTTP client
    response = LanguageOperator::Dsl::HTTP.get(url, headers: { 'User-Agent' => 'Mozilla/5.0' }, follow_redirects: true)

    next "Error: Failed to fetch URL: #{url} - #{response[:error] || response[:status]}" unless response[:success]

    content = response[:body]

    if return_html
      content
    else
      # Strip HTML tags for text-only output
      text = WebHelpers.strip_html_and_normalize(content)

      if text.empty?
        "No text content found at: #{url}"
      else
        truncated = WebHelpers.truncate_content(text)
        "Content from #{url}:\n\n#{truncated}"
      end
    end
  end
end

tool 'web_headers' do
  description 'Fetch HTTP headers from a URL'

  parameter 'url' do
    type :string
    required true
    description 'The URL to check'
  end

  execute do |params|
    url = params['url']

    # Validate URL
    error = LanguageOperator::Validators.http_url(url)
    next error if error

    # Fetch headers using SDK HTTP client
    response = LanguageOperator::Dsl::HTTP.head(url)

    unless response[:success]
      next "Error: Failed to fetch headers from: #{url} - #{response[:error] || response[:status]}"
    end

    headers_text = response[:headers].map { |k, v| "#{k}: #{Array(v).join(', ')}" }.join("\n")
    "Headers for #{url}:\n\n#{headers_text}"
  end
end

tool 'web_status' do
  description 'Check the HTTP status code of a URL'

  parameter 'url' do
    type :string
    required true
    description 'The URL to check'
  end

  execute do |params|
    url = params['url']

    # Validate URL
    error = LanguageOperator::Validators.http_url(url)
    next error if error

    # Get status code using SDK HTTP client (don't follow redirects to get actual status)
    response = LanguageOperator::Dsl::HTTP.get(url, follow_redirects: false)

    status = response[:status] || 0
    status_text = WebHelpers.status_description(status)

    "Status for #{url}: #{status} #{status_text}"
  end
end

tool 'web_request' do
  description 'Make HTTP requests to APIs with full control over method, headers, body, and retries'

  parameter 'url' do
    type :string
    required true
    description 'The URL to request'
  end

  parameter 'method' do
    type :string
    required false
    description 'HTTP method (GET, POST, PUT, DELETE, HEAD) - default: GET'
    default 'GET'
  end

  parameter 'headers' do
    type :string
    required false
    description 'JSON object of headers (e.g., {"Authorization": "Bearer token", "Content-Type": "application/json"})'
  end

  parameter 'body' do
    type :string
    required false
    description 'Request body (for POST, PUT)'
  end

  parameter 'query_params' do
    type :string
    required false
    description 'JSON object of query parameters (e.g., {"key": "value", "limit": "10"})'
  end

  parameter 'timeout' do
    type :number
    required false
    description 'Request timeout in seconds (default: 30)'
    default 30
  end

  parameter 'max_retries' do
    type :number
    required false
    description 'Maximum number of retries for transient failures (default: 3)'
    default 3
  end

  parameter 'follow_redirects' do
    type :boolean
    required false
    description 'Follow HTTP redirects (default: true)'
    default true
  end

  execute do |params|
    url = params['url']
    method = (params['method'] || 'GET').upcase
    timeout = params['timeout'] || 30
    max_retries = params['max_retries'] || 3
    follow_redirects = params.key?('follow_redirects') ? params['follow_redirects'] : true

    # Validate URL
    error = LanguageOperator::Validators.http_url(url)
    next error if error

    # Validate method
    valid_methods = %w[GET POST PUT DELETE HEAD]
    next LanguageOperator::Validators.one_of(method, valid_methods, 'HTTP method') unless valid_methods.include?(method)

    # Parse headers
    headers = {}
    if params['headers']
      parsed = WebHelpers.parse_json(params['headers'])
      next LanguageOperator::Errors.invalid_json('headers') if parsed.nil?

      headers = parsed
    end

    # Parse query params and append to URL
    if params['query_params']
      parsed = WebHelpers.parse_json(params['query_params'])
      next LanguageOperator::Errors.invalid_json('query_params') if parsed.nil?

      url += WebHelpers.build_query_string(parsed)
    end

    # Get request body
    body = params['body']

    # Execute request with retry logic
    response = nil
    attempt = 0
    last_error = nil

    while attempt <= max_retries
      response = case method
                 when 'GET'
                   LanguageOperator::Dsl::HTTP.get(url, headers: headers, timeout: timeout,
                                                        follow_redirects: follow_redirects)
                 when 'POST'
                   LanguageOperator::Dsl::HTTP.post(url, body: body, headers: headers, timeout: timeout)
                 when 'PUT'
                   LanguageOperator::Dsl::HTTP.put(url, body: body, headers: headers, timeout: timeout)
                 when 'DELETE'
                   LanguageOperator::Dsl::HTTP.delete(url, headers: headers, timeout: timeout)
                 when 'HEAD'
                   LanguageOperator::Dsl::HTTP.head(url, headers: headers, timeout: timeout)
                 end

      # Check if we should retry (retryable status code or network error)
      should_retry = false
      if response
        # Network/HTTP error from SDK
        if response[:error]
          last_error = response[:error]
          should_retry = (attempt < max_retries)
        # Retryable HTTP status code
        elsif LanguageOperator::Retry.retryable_http_code?(response[:status])
          should_retry = (attempt < max_retries)
        end
      end

      if should_retry
        attempt += 1
        delay = LanguageOperator::Retry.calculate_backoff(attempt)
        sleep delay
        next
      end

      break
    end

    # Handle errors
    next "Error: Request failed after #{attempt + 1} attempts - #{last_error}" if last_error

    next 'Error: No response received' unless response

    # Format response
    status = response[:status] || 0
    status_text = WebHelpers.status_description(status)
    result = []
    result << "HTTP #{method} #{url}"
    result << "Status: #{status} #{status_text}"
    result << ''

    if response[:headers] && !response[:headers].empty?
      result << 'Headers:'
      response[:headers].each do |k, v|
        result << "  #{k}: #{Array(v).join(', ')}"
      end
      result << ''
    end

    if response[:body] && !response[:body].empty?
      body_preview = response[:body]
      # Try to pretty-print JSON
      if headers['Content-Type']&.include?('json') || response[:headers]&.dig('content-type')&.to_s&.include?('json')
        parsed = WebHelpers.parse_json(body_preview)
        body_preview = JSON.pretty_generate(parsed) if parsed
      end

      result << 'Body:'
      result << WebHelpers.truncate_content(body_preview, 5000)
    else
      result << 'Body: (empty)'
    end

    result.join("\n")
  end
end

tool 'web_post' do
  description 'Simplified POST request for JSON APIs'

  parameter 'url' do
    type :string
    required true
    description 'The URL to POST to'
  end

  parameter 'data' do
    type :string
    required true
    description 'JSON object to send as request body'
  end

  parameter 'headers' do
    type :string
    required false
    description 'Additional headers as JSON object (Content-Type: application/json is set automatically)'
  end

  parameter 'timeout' do
    type :number
    required false
    description 'Request timeout in seconds (default: 30)'
    default 30
  end

  execute do |params|
    url = params['url']
    data = params['data']
    timeout = params['timeout'] || 30

    # Validate URL
    error = LanguageOperator::Validators.http_url(url)
    next error if error

    # Parse and validate data JSON
    parsed_data = WebHelpers.parse_json(data)
    next LanguageOperator::Errors.invalid_json('data') if parsed_data.nil?

    # Build headers with JSON content type
    headers = { 'Content-Type' => 'application/json' }

    if params['headers']
      custom_headers = WebHelpers.parse_json(params['headers'])
      next LanguageOperator::Errors.invalid_json('headers') if custom_headers.nil?

      headers.merge!(custom_headers)
    end

    # Make POST request
    response = LanguageOperator::Dsl::HTTP.post(url, body: data, headers: headers, timeout: timeout)

    next "Error: POST failed - #{response[:error] || "HTTP #{response[:status]}"}" unless response[:success]

    status = response[:status] || 0
    status_text = WebHelpers.status_description(status)

    result = []
    result << "POST #{url}"
    result << "Status: #{status} #{status_text}"
    result << ''

    if response[:body] && !response[:body].empty?
      body_preview = response[:body]
      parsed = WebHelpers.parse_json(body_preview)
      body_preview = JSON.pretty_generate(parsed) if parsed

      result << 'Response:'
      result << WebHelpers.truncate_content(body_preview, 5000)
    else
      result << 'Response: (empty)'
    end

    result.join("\n")
  end
end

tool 'web_parse' do
  description 'Parse and extract data from HTTP response body (JSON, XML, or text)'

  parameter 'url' do
    type :string
    required true
    description 'The URL to fetch and parse'
  end

  parameter 'format' do
    type :string
    required false
    description 'Expected format: json, xml, or text (auto-detected if not specified)'
  end

  parameter 'json_path' do
    type :string
    required false
    description "JSON path to extract (e.g., 'data.items' for nested field)"
  end

  execute do |params|
    url = params['url']
    format = params['format']
    json_path = params['json_path']

    # Validate URL
    error = LanguageOperator::Validators.http_url(url)
    next error if error

    # Fetch the URL
    response = LanguageOperator::Dsl::HTTP.get(url, follow_redirects: true)

    next "Error: Failed to fetch URL - #{response[:error] || "HTTP #{response[:status]}"}" unless response[:success]

    body = response[:body]
    next 'Error: Empty response body' if body.nil? || body.empty?

    # Auto-detect format if not specified
    if format.nil?
      content_type = response[:headers]&.dig('content-type').to_s
      format = if content_type.include?('json')
                 'json'
               elsif content_type.include?('xml')
                 'xml'
               else
                 'text'
               end
    end

    # Parse based on format
    case format.downcase
    when 'json'
      parsed = WebHelpers.parse_json(body)
      next 'Error: Invalid JSON in response body' if parsed.nil?

      # Extract JSON path if specified
      if json_path
        parts = json_path.split('.')
        result = parsed
        parts.each do |part|
          if result.is_a?(Hash) && result.key?(part)
            result = result[part]
          elsif result.is_a?(Array) && part.to_i.to_s == part
            result = result[part.to_i]
          else
            # Path not found
            result = nil
            break
          end
        end

        next "Error: JSON path '#{json_path}' not found" if result.nil?

        JSON.pretty_generate(result)
      else
        JSON.pretty_generate(parsed)
      end
    when 'xml'
      # Basic XML display (no parsing library available)
      WebHelpers.truncate_content(body, 5000)
    when 'text'
      text = WebHelpers.strip_html_and_normalize(body)
      WebHelpers.truncate_content(text, 5000)
    else
      next "Error: Unsupported format '#{format}'. Use json, xml, or text"
    end
  end
end
