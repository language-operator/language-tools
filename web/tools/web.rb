# Web search and scraping tools for MCP

require 'json'
require 'uri'

# Helper methods for web tools
module WebHelpers
  # Content truncation limit for text output
  CONTENT_TRUNCATION_LIMIT = 2000

  # HTML stripping patterns
  HTML_STRIP_PATTERNS = [
    /<script[^>]*>.*?<\/script>/im,
    /<style[^>]*>.*?<\/style>/im,
    /<[^>]+>/
  ].freeze

  # Common HTTP status codes
  HTTP_STATUS_CODES = {
    200 => "OK",
    201 => "Created",
    204 => "No Content",
    301 => "Moved Permanently",
    302 => "Found (Redirect)",
    304 => "Not Modified",
    400 => "Bad Request",
    401 => "Unauthorized",
    403 => "Forbidden",
    404 => "Not Found",
    422 => "Unprocessable Entity",
    429 => "Too Many Requests",
    500 => "Internal Server Error",
    502 => "Bad Gateway",
    503 => "Service Unavailable",
    504 => "Gateway Timeout"
  }.freeze

  # Validate HTTP/HTTPS URL
  # @param url [String] URL to validate
  # @return [String, nil] Error message if invalid, nil if valid
  def self.validate_http_url(url)
    return nil if url =~ /^https?:\/\//
    "Error: Invalid URL. Must start with http:// or https://"
  end

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
    HTTP_STATUS_CODES.fetch(status, "Unknown")
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
    '?' + URI.encode_www_form(params)
  end
end

# Retry logic helpers for API requests
module RetryHelpers
  # Default retry configuration
  MAX_RETRIES = 3
  BASE_DELAY = 1.0
  MAX_DELAY = 10.0
  JITTER_FACTOR = 0.1

  # Retryable HTTP status codes (transient errors)
  RETRYABLE_STATUS_CODES = [429, 500, 502, 503, 504].freeze

  # Execute block with retry logic
  # @param max_retries [Integer] Maximum retry attempts
  # @return [Object] Block return value
  def self.with_retry(max_retries = MAX_RETRIES)
    retries = 0
    begin
      yield
    rescue StandardError => e
      if retries < max_retries
        retries += 1
        delay = calculate_backoff(retries)
        sleep delay
        retry
      end
      raise e
    end
  end

  # Calculate exponential backoff with jitter
  # @param attempt [Integer] Retry attempt number (1-based)
  # @return [Float] Delay in seconds
  def self.calculate_backoff(attempt)
    exponential = BASE_DELAY * (2**(attempt - 1))
    capped = [exponential, MAX_DELAY].min
    jitter = capped * JITTER_FACTOR * (rand - 0.5)
    capped + jitter
  end

  # Check if status code is retryable
  # @param status [Integer] HTTP status code
  # @return [Boolean] True if should retry
  def self.retryable_status?(status)
    RETRYABLE_STATUS_CODES.include?(status)
  end
end

tool "web_search" do
  description "Search the web using DuckDuckGo and return results"

  parameter "query" do
    type :string
    required true
    description "The search query"
  end

  parameter "max_results" do
    type :number
    required false
    description "Maximum number of results to return (default: 5)"
    default 5
  end

  execute do |params|
    query = params["query"]
    max_results = (params["max_results"] || 5).to_i

    # URL encode the query
    encoded_query = URI.encode_www_form_component(query)

    # Use DuckDuckGo HTML interface
    url = "https://html.duckduckgo.com/html/?q=#{encoded_query}"

    # Fetch results using SDK HTTP client
    response = LanguageOperator::Dsl::HTTP.get(url, headers: { 'User-Agent' => 'Mozilla/5.0' }, follow_redirects: true)

    unless response[:success]
      next "Error: Failed to fetch search results - #{response[:error] || response[:status]}"
    end

    html = response[:body]

    # Parse results (simple text extraction)
    results = []

    # Extract result blocks using simple pattern matching
    html.scan(/<a[^>]+class="[^"]*result__a[^"]*"[^>]+href="([^"]+)"[^>]*>([^<]+)<\/a>/i).each_with_index do |(href, title), index|
      break if index >= max_results

      # Clean up the URL (DuckDuckGo redirects)
      clean_url = href.gsub(/^\/\/duckduckgo\.com\/l\/\?.*uddg=/, '')
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

tool "web_fetch" do
  description "Fetch and extract text content from a URL"

  parameter "url" do
    type :string
    required true
    description "The URL to fetch"
  end

  parameter "html" do
    type :boolean
    required false
    description "Return raw HTML instead of text (default: false)"
    default false
  end

  execute do |params|
    url = params["url"]
    return_html = params["html"] || false

    # Validate URL
    error = WebHelpers.validate_http_url(url)
    next error if error

    # Fetch the URL using SDK HTTP client
    response = LanguageOperator::Dsl::HTTP.get(url, headers: { 'User-Agent' => 'Mozilla/5.0' }, follow_redirects: true)

    unless response[:success]
      next "Error: Failed to fetch URL: #{url} - #{response[:error] || response[:status]}"
    end

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

tool "web_headers" do
  description "Fetch HTTP headers from a URL"

  parameter "url" do
    type :string
    required true
    description "The URL to check"
  end

  execute do |params|
    url = params["url"]

    # Validate URL
    error = WebHelpers.validate_http_url(url)
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

tool "web_status" do
  description "Check the HTTP status code of a URL"

  parameter "url" do
    type :string
    required true
    description "The URL to check"
  end

  execute do |params|
    url = params["url"]

    # Validate URL
    error = WebHelpers.validate_http_url(url)
    next error if error

    # Get status code using SDK HTTP client (don't follow redirects to get actual status)
    response = LanguageOperator::Dsl::HTTP.get(url, follow_redirects: false)

    status = response[:status] || 0
    status_text = WebHelpers.status_description(status)

    "Status for #{url}: #{status} #{status_text}"
  end
end

tool "web_request" do
  description "Make HTTP requests to APIs with full control over method, headers, body, and retries"

  parameter "url" do
    type :string
    required true
    description "The URL to request"
  end

  parameter "method" do
    type :string
    required false
    description "HTTP method (GET, POST, PUT, DELETE, HEAD) - default: GET"
    default "GET"
  end

  parameter "headers" do
    type :string
    required false
    description "JSON object of headers (e.g., {\"Authorization\": \"Bearer token\", \"Content-Type\": \"application/json\"})"
  end

  parameter "body" do
    type :string
    required false
    description "Request body (for POST, PUT)"
  end

  parameter "query_params" do
    type :string
    required false
    description "JSON object of query parameters (e.g., {\"key\": \"value\", \"limit\": \"10\"})"
  end

  parameter "timeout" do
    type :number
    required false
    description "Request timeout in seconds (default: 30)"
    default 30
  end

  parameter "max_retries" do
    type :number
    required false
    description "Maximum number of retries for transient failures (default: 3)"
    default 3
  end

  parameter "follow_redirects" do
    type :boolean
    required false
    description "Follow HTTP redirects (default: true)"
    default true
  end

  execute do |params|
    url = params["url"]
    method = (params["method"] || "GET").upcase
    timeout = params["timeout"] || 30
    max_retries = params["max_retries"] || 3
    follow_redirects = params.key?("follow_redirects") ? params["follow_redirects"] : true

    # Validate URL
    error = WebHelpers.validate_http_url(url)
    next error if error

    # Validate method
    valid_methods = %w[GET POST PUT DELETE HEAD]
    unless valid_methods.include?(method)
      next "Error: Invalid HTTP method '#{method}'. Must be one of: #{valid_methods.join(', ')}"
    end

    # Parse headers
    headers = {}
    if params["headers"]
      parsed = WebHelpers.parse_json(params["headers"])
      if parsed.nil?
        next "Error: Invalid JSON in headers parameter"
      end
      headers = parsed
    end

    # Parse query params and append to URL
    if params["query_params"]
      parsed = WebHelpers.parse_json(params["query_params"])
      if parsed.nil?
        next "Error: Invalid JSON in query_params parameter"
      end
      url += WebHelpers.build_query_string(parsed)
    end

    # Get request body
    body = params["body"]

    # Execute request with retry logic
    response = nil
    attempt = 0
    last_error = nil

    while attempt <= max_retries
      response = case method
                 when "GET"
                   LanguageOperator::Dsl::HTTP.get(url, headers: headers, timeout: timeout, follow_redirects: follow_redirects)
                 when "POST"
                   LanguageOperator::Dsl::HTTP.post(url, body: body, headers: headers, timeout: timeout)
                 when "PUT"
                   LanguageOperator::Dsl::HTTP.put(url, body: body, headers: headers, timeout: timeout)
                 when "DELETE"
                   LanguageOperator::Dsl::HTTP.delete(url, headers: headers, timeout: timeout)
                 when "HEAD"
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
        elsif RetryHelpers.retryable_status?(response[:status])
          should_retry = (attempt < max_retries)
        end
      end

      if should_retry
        attempt += 1
        delay = RetryHelpers.calculate_backoff(attempt)
        sleep delay
        next
      end

      break
    end

    # Handle errors
    if last_error
      next "Error: Request failed after #{attempt + 1} attempts - #{last_error}"
    end

    unless response
      next "Error: No response received"
    end

    # Format response
    status = response[:status] || 0
    status_text = WebHelpers.status_description(status)
    result = []
    result << "HTTP #{method} #{url}"
    result << "Status: #{status} #{status_text}"
    result << ""

    if response[:headers] && !response[:headers].empty?
      result << "Headers:"
      response[:headers].each do |k, v|
        result << "  #{k}: #{Array(v).join(', ')}"
      end
      result << ""
    end

    if response[:body] && !response[:body].empty?
      body_preview = response[:body]
      # Try to pretty-print JSON
      if headers.dig("Content-Type")&.include?("json") || response[:headers]&.dig("content-type")&.to_s&.include?("json")
        parsed = WebHelpers.parse_json(body_preview)
        body_preview = JSON.pretty_generate(parsed) if parsed
      end

      result << "Body:"
      result << WebHelpers.truncate_content(body_preview, 5000)
    else
      result << "Body: (empty)"
    end

    result.join("\n")
  end
end

tool "web_post" do
  description "Simplified POST request for JSON APIs"

  parameter "url" do
    type :string
    required true
    description "The URL to POST to"
  end

  parameter "data" do
    type :string
    required true
    description "JSON object to send as request body"
  end

  parameter "headers" do
    type :string
    required false
    description "Additional headers as JSON object (Content-Type: application/json is set automatically)"
  end

  parameter "timeout" do
    type :number
    required false
    description "Request timeout in seconds (default: 30)"
    default 30
  end

  execute do |params|
    url = params["url"]
    data = params["data"]
    timeout = params["timeout"] || 30

    # Validate URL
    error = WebHelpers.validate_http_url(url)
    next error if error

    # Parse and validate data JSON
    parsed_data = WebHelpers.parse_json(data)
    if parsed_data.nil?
      next "Error: Invalid JSON in data parameter"
    end

    # Build headers with JSON content type
    headers = { "Content-Type" => "application/json" }

    if params["headers"]
      custom_headers = WebHelpers.parse_json(params["headers"])
      if custom_headers.nil?
        next "Error: Invalid JSON in headers parameter"
      end
      headers.merge!(custom_headers)
    end

    # Make POST request
    response = LanguageOperator::Dsl::HTTP.post(url, body: data, headers: headers, timeout: timeout)

    unless response[:success]
      next "Error: POST failed - #{response[:error] || "HTTP #{response[:status]}"}"
    end

    status = response[:status] || 0
    status_text = WebHelpers.status_description(status)

    result = []
    result << "POST #{url}"
    result << "Status: #{status} #{status_text}"
    result << ""

    if response[:body] && !response[:body].empty?
      body_preview = response[:body]
      parsed = WebHelpers.parse_json(body_preview)
      body_preview = JSON.pretty_generate(parsed) if parsed

      result << "Response:"
      result << WebHelpers.truncate_content(body_preview, 5000)
    else
      result << "Response: (empty)"
    end

    result.join("\n")
  end
end

tool "web_parse" do
  description "Parse and extract data from HTTP response body (JSON, XML, or text)"

  parameter "url" do
    type :string
    required true
    description "The URL to fetch and parse"
  end

  parameter "format" do
    type :string
    required false
    description "Expected format: json, xml, or text (auto-detected if not specified)"
  end

  parameter "json_path" do
    type :string
    required false
    description "JSON path to extract (e.g., 'data.items' for nested field)"
  end

  execute do |params|
    url = params["url"]
    format = params["format"]
    json_path = params["json_path"]

    # Validate URL
    error = WebHelpers.validate_http_url(url)
    next error if error

    # Fetch the URL
    response = LanguageOperator::Dsl::HTTP.get(url, follow_redirects: true)

    unless response[:success]
      next "Error: Failed to fetch URL - #{response[:error] || "HTTP #{response[:status]}"}"
    end

    body = response[:body]
    if body.nil? || body.empty?
      next "Error: Empty response body"
    end

    # Auto-detect format if not specified
    if format.nil?
      content_type = response[:headers]&.dig("content-type")&.to_s || ""
      format = if content_type.include?("json")
                 "json"
               elsif content_type.include?("xml")
                 "xml"
               else
                 "text"
               end
    end

    # Parse based on format
    case format.downcase
    when "json"
      parsed = WebHelpers.parse_json(body)
      if parsed.nil?
        next "Error: Invalid JSON in response body"
      end

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

        if result.nil?
          next "Error: JSON path '#{json_path}' not found"
        end

        JSON.pretty_generate(result)
      else
        JSON.pretty_generate(parsed)
      end
    when "xml"
      # Basic XML display (no parsing library available)
      WebHelpers.truncate_content(body, 5000)
    when "text"
      text = WebHelpers.strip_html_and_normalize(body)
      WebHelpers.truncate_content(text, 5000)
    else
      next "Error: Unsupported format '#{format}'. Use json, xml, or text"
    end
  end
end
