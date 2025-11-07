# Web search and scraping tools for MCP

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
    301 => "Moved Permanently",
    302 => "Found (Redirect)",
    304 => "Not Modified",
    400 => "Bad Request",
    401 => "Unauthorized",
    403 => "Forbidden",
    404 => "Not Found",
    500 => "Internal Server Error",
    502 => "Bad Gateway",
    503 => "Service Unavailable"
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
