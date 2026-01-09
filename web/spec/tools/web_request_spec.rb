# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe 'web_request tool' do
  let(:registry) { LanguageOperator::Dsl::Registry.new }
  let(:tool_path) { File.expand_path('../../tools/web.rb', __dir__) }

  before do
    context = LanguageOperator::Dsl::Context.new(registry)
    code = File.read(tool_path)
    context.instance_eval(code, tool_path)
  end

  describe 'HTTP methods' do
    it 'makes GET requests' do
      stub_request(:get, 'https://example.com/users')
        .to_return(status: 200, body: '{"users":[]}', headers: { 'Content-Type' => 'application/json' })

      tool = registry.get('web_request')
      result = tool.call('url' => 'https://example.com/users', 'method' => 'GET')

      expect(result).to include('HTTP GET https://example.com/users')
      expect(result).to include('Status: 200 OK')
      expect(result).to include('"users"')
    end

    it 'makes POST requests' do
      stub_request(:post, 'https://example.com/users')
        .with(body: '{"name":"John"}')
        .to_return(status: 201, body: '{"id":1,"name":"John"}', headers: { 'Content-Type' => 'application/json' })

      tool = registry.get('web_request')
      result = tool.call(
        'url' => 'https://example.com/users',
        'method' => 'POST',
        'body' => '{"name":"John"}'
      )

      expect(result).to include('HTTP POST https://example.com/users')
      expect(result).to include('Status: 201 Created')
      expect(result).to include('"id"')
    end

    it 'makes PUT requests' do
      stub_request(:put, 'https://example.com/users/1')
        .with(body: '{"name":"Jane"}')
        .to_return(status: 200, body: '{"id":1,"name":"Jane"}')

      tool = registry.get('web_request')
      result = tool.call(
        'url' => 'https://example.com/users/1',
        'method' => 'PUT',
        'body' => '{"name":"Jane"}'
      )

      expect(result).to include('HTTP PUT')
      expect(result).to include('Status: 200 OK')
    end

    it 'makes DELETE requests' do
      stub_request(:delete, 'https://example.com/users/1')
        .to_return(status: 204, body: '')

      tool = registry.get('web_request')
      result = tool.call(
        'url' => 'https://example.com/users/1',
        'method' => 'DELETE'
      )

      expect(result).to include('HTTP DELETE')
      expect(result).to include('Status: 204 No Content')
      expect(result).to include('Body: (empty)')
    end

    it 'makes HEAD requests' do
      stub_request(:head, 'https://example.com/users')
        .to_return(status: 200, headers: { 'Content-Type' => 'application/json' })

      tool = registry.get('web_request')
      result = tool.call(
        'url' => 'https://example.com/users',
        'method' => 'HEAD'
      )

      expect(result).to include('HTTP HEAD')
      expect(result).to include('Status: 200 OK')
    end

    it 'defaults to GET when method not specified' do
      stub_request(:get, 'https://example.com/test')
        .to_return(status: 200, body: 'test')

      tool = registry.get('web_request')
      result = tool.call('url' => 'https://example.com/test')

      expect(result).to include('HTTP GET')
    end

    it 'rejects invalid HTTP methods' do
      tool = registry.get('web_request')
      result = tool.call('url' => 'https://example.com/test', 'method' => 'INVALID')

      expect(result).to include('Error: Invalid HTTP method')
    end
  end

  describe 'custom headers' do
    it 'sends custom headers' do
      stub_request(:get, 'https://example.com/protected')
        .with(headers: { 'Authorization' => 'Bearer token123' })
        .to_return(status: 200, body: '{"data":"secret"}')

      tool = registry.get('web_request')
      result = tool.call(
        'url' => 'https://example.com/protected',
        'headers' => '{"Authorization":"Bearer token123"}'
      )

      expect(result).to include('Status: 200 OK')
      expect(result).to include('secret')
    end

    it 'sends multiple custom headers' do
      stub_request(:post, 'https://example.com/data')
        .with(
          headers: {
            'Authorization' => 'Bearer token123',
            'Content-Type' => 'application/json',
            'X-Custom-Header' => 'value'
          }
        )
        .to_return(status: 201, body: '{"created":true}')

      tool = registry.get('web_request')
      result = tool.call(
        'url' => 'https://example.com/data',
        'method' => 'POST',
        'headers' => '{"Authorization":"Bearer token123","Content-Type":"application/json","X-Custom-Header":"value"}',
        'body' => '{}'
      )

      expect(result).to include('Status: 201 Created')
    end

    it 'returns error for invalid JSON in headers' do
      tool = registry.get('web_request')
      result = tool.call(
        'url' => 'https://example.com/test',
        'headers' => 'not-valid-json'
      )

      expect(result).to include('Error: Invalid JSON in headers parameter')
    end
  end

  describe 'query parameters' do
    it 'appends query parameters to URL' do
      stub_request(:get, 'https://example.com/search?q=test&limit=10')
        .to_return(status: 200, body: '{"results":[]}')

      tool = registry.get('web_request')
      result = tool.call(
        'url' => 'https://example.com/search',
        'query_params' => '{"q":"test","limit":"10"}'
      )

      expect(result).to include('Status: 200 OK')
    end

    it 'returns error for invalid JSON in query_params' do
      tool = registry.get('web_request')
      result = tool.call(
        'url' => 'https://example.com/test',
        'query_params' => 'not-valid-json'
      )

      expect(result).to include('Error: Invalid JSON in query_params parameter')
    end
  end

  describe 'retry logic' do
    it 'retries on 503 errors' do
      stub_request(:get, 'https://example.com/flaky')
        .to_return(status: 503).then
        .to_return(status: 503).then
        .to_return(status: 200, body: '{"success":true}')

      tool = registry.get('web_request')
      result = tool.call(
        'url' => 'https://example.com/flaky',
        'max_retries' => 3
      )

      expect(result).to include('Status: 200 OK')
      expect(result).to include('success')
    end

    it 'retries on 500 errors' do
      stub_request(:get, 'https://example.com/error')
        .to_return(status: 500).then
        .to_return(status: 200, body: 'ok')

      tool = registry.get('web_request')
      result = tool.call('url' => 'https://example.com/error')

      expect(result).to include('Status: 200 OK')
    end

    it 'stops retrying after max_retries exceeded' do
      stub_request(:get, 'https://example.com/always-fails')
        .to_return(status: 503).times(5)

      tool = registry.get('web_request')
      result = tool.call(
        'url' => 'https://example.com/always-fails',
        'max_retries' => 2
      )

      expect(result).to include('Status: 503 Service Unavailable')
    end

    it 'does not retry on 404 errors' do
      stub_request(:get, 'https://example.com/notfound')
        .to_return(status: 404, body: 'Not Found')

      tool = registry.get('web_request')
      result = tool.call('url' => 'https://example.com/notfound')

      expect(result).to include('Status: 404 Not Found')
    end
  end

  describe 'response formatting' do
    it 'pretty-prints JSON responses' do
      stub_request(:get, 'https://example.com/data')
        .to_return(
          status: 200,
          body: '{"users":[{"id":1,"name":"Alice"},{"id":2,"name":"Bob"}]}',
          headers: { 'Content-Type' => 'application/json' }
        )

      tool = registry.get('web_request')
      result = tool.call('url' => 'https://example.com/data')

      expect(result).to include('Status: 200 OK')
      expect(result).to include('"users"')
      expect(result).to include('"Alice"')
    end

    it 'includes response headers' do
      stub_request(:get, 'https://example.com/test')
        .to_return(
          status: 200,
          body: 'test',
          headers: {
            'Content-Type' => 'text/plain',
            'X-Custom-Header' => 'value'
          }
        )

      tool = registry.get('web_request')
      result = tool.call('url' => 'https://example.com/test')

      expect(result).to include('Headers:')
      expect(result).to include('content-type')
      expect(result).to include('x-custom-header')
    end
  end

  describe 'error handling' do
    it 'handles network errors gracefully' do
      stub_request(:get, 'https://example.com/timeout')
        .to_timeout

      tool = registry.get('web_request')
      result = tool.call('url' => 'https://example.com/timeout', 'max_retries' => 0)

      expect(result).to include('Error: Request failed')
      expect(result).to include('execution expired')
    end

    it 'returns error after all retries exhausted' do
      stub_request(:get, 'https://example.com/always-timeout')
        .to_timeout.times(5)

      tool = registry.get('web_request')
      result = tool.call(
        'url' => 'https://example.com/always-timeout',
        'max_retries' => 2
      )

      expect(result).to include('Error: Request failed after')
    end
  end

  describe 'URL validation' do
    it 'rejects URLs without http:// or https://' do
      tool = registry.get('web_request')
      result = tool.call('url' => 'example.com')

      expect(result).to include('Error: Invalid URL')
    end

    it 'accepts http:// URLs' do
      stub_request(:get, 'http://example.com/test')
        .to_return(status: 200, body: 'ok')

      tool = registry.get('web_request')
      result = tool.call('url' => 'http://example.com/test')

      expect(result).to include('Status: 200 OK')
    end
  end
end
