require_relative '../spec_helper'

RSpec.describe 'web_post tool' do
  let(:registry) { LanguageOperator::Dsl::Registry.new }
  let(:tool_path) { File.expand_path('../../tools/web.rb', __dir__) }

  before do
    context = LanguageOperator::Dsl::Context.new(registry)
    code = File.read(tool_path)
    context.instance_eval(code, tool_path)
  end

  describe 'basic POST functionality' do
    it 'makes POST requests with JSON data' do
      stub_request(:post, 'https://api.example.com/users')
        .with(
          body: '{"name":"Alice","email":"alice@example.com"}',
          headers: { 'Content-Type' => 'application/json' }
        )
        .to_return(
          status: 201,
          body: '{"id":1,"name":"Alice","email":"alice@example.com"}',
          headers: { 'Content-Type' => 'application/json' }
        )

      tool = registry.get('web_post')
      result = tool.call(
        'url' => 'https://api.example.com/users',
        'data' => '{"name":"Alice","email":"alice@example.com"}'
      )

      expect(result).to include('POST https://api.example.com/users')
      expect(result).to include('Status: 201 Created')
      expect(result).to include('"id"')
      expect(result).to include('"Alice"')
    end

    it 'automatically sets Content-Type to application/json' do
      stub_request(:post, 'https://api.example.com/data')
        .with(headers: { 'Content-Type' => 'application/json' })
        .to_return(status: 200, body: '{"success":true}')

      tool = registry.get('web_post')
      result = tool.call(
        'url' => 'https://api.example.com/data',
        'data' => '{}'
      )

      expect(result).to include('Status: 200 OK')
    end

    it 'pretty-prints JSON response' do
      stub_request(:post, 'https://api.example.com/test')
        .to_return(
          status: 200,
          body: '{"users":[{"id":1,"name":"Bob"}],"count":1}',
          headers: { 'Content-Type' => 'application/json' }
        )

      tool = registry.get('web_post')
      result = tool.call(
        'url' => 'https://api.example.com/test',
        'data' => '{}'
      )

      expect(result).to include('"users"')
      expect(result).to include('"Bob"')
      expect(result).to include('"count"')
    end
  end

  describe 'custom headers' do
    it 'merges custom headers with default Content-Type' do
      stub_request(:post, 'https://api.example.com/protected')
        .with(
          headers: {
            'Content-Type' => 'application/json',
            'Authorization' => 'Bearer token123'
          }
        )
        .to_return(status: 200, body: '{"success":true}')

      tool = registry.get('web_post')
      result = tool.call(
        'url' => 'https://api.example.com/protected',
        'data' => '{}',
        'headers' => '{"Authorization":"Bearer token123"}'
      )

      expect(result).to include('Status: 200 OK')
    end

    it 'allows adding extra headers while keeping Content-Type' do
      stub_request(:post, 'https://api.example.com/data')
        .with(
          headers: {
            'Content-Type' => 'application/json',
            'X-API-Key' => 'secret123'
          },
          body: '{"test":true}'
        )
        .to_return(status: 200, body: '{"ok":true}')

      tool = registry.get('web_post')
      result = tool.call(
        'url' => 'https://api.example.com/data',
        'data' => '{"test":true}',
        'headers' => '{"X-API-Key":"secret123"}'
      )

      expect(result).to include('Status: 200 OK')
    end

    it 'returns error for invalid JSON in headers' do
      tool = registry.get('web_post')
      result = tool.call(
        'url' => 'https://api.example.com/test',
        'data' => '{}',
        'headers' => 'not-json'
      )

      expect(result).to include('Error: Invalid JSON in headers parameter')
    end
  end

  describe 'data validation' do
    it 'validates data parameter is valid JSON' do
      tool = registry.get('web_post')
      result = tool.call(
        'url' => 'https://api.example.com/test',
        'data' => 'not-valid-json'
      )

      expect(result).to include('Error: Invalid JSON in data parameter')
    end

    it 'accepts empty JSON object' do
      stub_request(:post, 'https://api.example.com/test')
        .with(body: '{}')
        .to_return(status: 200, body: '{"ok":true}')

      tool = registry.get('web_post')
      result = tool.call(
        'url' => 'https://api.example.com/test',
        'data' => '{}'
      )

      expect(result).to include('Status: 200 OK')
    end

    it 'accepts JSON arrays' do
      stub_request(:post, 'https://api.example.com/batch')
        .with(body: '[{"id":1},{"id":2}]')
        .to_return(status: 200, body: '{"processed":2}')

      tool = registry.get('web_post')
      result = tool.call(
        'url' => 'https://api.example.com/batch',
        'data' => '[{"id":1},{"id":2}]'
      )

      expect(result).to include('Status: 200 OK')
    end
  end

  describe 'error handling' do
    it 'handles 400 errors' do
      stub_request(:post, 'https://api.example.com/users')
        .to_return(
          status: 400,
          body: '{"error":"Invalid input"}'
        )

      tool = registry.get('web_post')
      result = tool.call(
        'url' => 'https://api.example.com/users',
        'data' => '{"invalid":"data"}'
      )

      expect(result).to include('Error: POST failed')
    end

    it 'handles 500 errors' do
      stub_request(:post, 'https://api.example.com/error')
        .to_return(status: 500, body: 'Internal Server Error')

      tool = registry.get('web_post')
      result = tool.call(
        'url' => 'https://api.example.com/error',
        'data' => '{}'
      )

      expect(result).to include('Error: POST failed')
    end

    it 'handles network timeouts' do
      stub_request(:post, 'https://api.example.com/slow')
        .to_timeout

      tool = registry.get('web_post')
      result = tool.call(
        'url' => 'https://api.example.com/slow',
        'data' => '{}'
      )

      expect(result).to include('Error: POST failed')
    end
  end

  describe 'empty response handling' do
    it 'handles empty response body' do
      stub_request(:post, 'https://api.example.com/delete')
        .to_return(status: 204, body: '')

      tool = registry.get('web_post')
      result = tool.call(
        'url' => 'https://api.example.com/delete',
        'data' => '{}'
      )

      expect(result).to include('Status: 204 No Content')
      expect(result).to include('Response: (empty)')
    end
  end

  describe 'URL validation' do
    it 'rejects URLs without http:// or https://' do
      tool = registry.get('web_post')
      result = tool.call(
        'url' => 'example.com',
        'data' => '{}'
      )

      expect(result).to include('Error: Invalid URL')
    end

    it 'accepts http:// URLs' do
      stub_request(:post, 'http://api.example.com/test')
        .to_return(status: 200, body: '{"ok":true}')

      tool = registry.get('web_post')
      result = tool.call(
        'url' => 'http://api.example.com/test',
        'data' => '{}'
      )

      expect(result).to include('Status: 200 OK')
    end
  end

  describe 'timeout configuration' do
    it 'accepts custom timeout parameter' do
      stub_request(:post, 'https://api.example.com/slow')
        .to_return(status: 200, body: '{"ok":true}')

      tool = registry.get('web_post')
      result = tool.call(
        'url' => 'https://api.example.com/slow',
        'data' => '{}',
        'timeout' => 60
      )

      expect(result).to include('Status: 200 OK')
    end
  end
end
