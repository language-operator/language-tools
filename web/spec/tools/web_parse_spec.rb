require_relative '../spec_helper'

RSpec.describe 'web_parse tool' do
  let(:registry) { LanguageOperator::Dsl::Registry.new }
  let(:tool_path) { File.expand_path('../../tools/web.rb', __dir__) }

  before do
    context = LanguageOperator::Dsl::Context.new(registry)
    code = File.read(tool_path)
    context.instance_eval(code, tool_path)
  end

  describe 'JSON parsing' do
    it 'parses and pretty-prints JSON' do
      stub_request(:get, 'https://api.example.com/users')
        .to_return(
          status: 200,
          body: '{"users":[{"id":1,"name":"Alice"},{"id":2,"name":"Bob"}],"count":2}',
          headers: { 'Content-Type' => 'application/json' }
        )

      tool = registry.get('web_parse')
      result = tool.call('url' => 'https://api.example.com/users')

      expect(result).to include('"users"')
      expect(result).to include('"Alice"')
      expect(result).to include('"Bob"')
      expect(result).to include('"count"')
    end

    it 'auto-detects JSON format from Content-Type header' do
      stub_request(:get, 'https://api.example.com/data.json')
        .to_return(
          status: 200,
          body: '{"test":true}',
          headers: { 'Content-Type' => 'application/json; charset=utf-8' }
        )

      tool = registry.get('web_parse')
      result = tool.call('url' => 'https://api.example.com/data.json')

      expect(result).to include('"test"')
      expect(result).to include('true')
    end

    it 'explicitly parses JSON when format is specified' do
      stub_request(:get, 'https://api.example.com/data')
        .to_return(
          status: 200,
          body: '{"value":123}',
          headers: { 'Content-Type' => 'text/plain' }
        )

      tool = registry.get('web_parse')
      result = tool.call(
        'url' => 'https://api.example.com/data',
        'format' => 'json'
      )

      expect(result).to include('"value"')
      expect(result).to include('123')
    end

    it 'returns error for invalid JSON' do
      stub_request(:get, 'https://api.example.com/invalid')
        .to_return(
          status: 200,
          body: 'not valid json',
          headers: { 'Content-Type' => 'application/json' }
        )

      tool = registry.get('web_parse')
      result = tool.call('url' => 'https://api.example.com/invalid')

      expect(result).to include('Error: Invalid JSON in response body')
    end
  end

  describe 'JSON path extraction' do
    it 'extracts nested fields using json_path' do
      stub_request(:get, 'https://api.example.com/response')
        .to_return(
          status: 200,
          body: '{"data":{"users":[{"id":1,"name":"Alice"}],"total":1}}',
          headers: { 'Content-Type' => 'application/json' }
        )

      tool = registry.get('web_parse')
      result = tool.call(
        'url' => 'https://api.example.com/response',
        'json_path' => 'data.users'
      )

      expect(result).to include('"Alice"')
      expect(result).not_to include('"total"')
    end

    it 'extracts top-level fields' do
      stub_request(:get, 'https://api.example.com/data')
        .to_return(
          status: 200,
          body: '{"users":[1,2,3],"metadata":{"count":3}}',
          headers: { 'Content-Type' => 'application/json' }
        )

      tool = registry.get('web_parse')
      result = tool.call(
        'url' => 'https://api.example.com/data',
        'json_path' => 'users'
      )

      expect(result).to include('[')
      expect(result).to include('1')
      expect(result).not_to include('metadata')
    end

    it 'extracts array elements by index' do
      stub_request(:get, 'https://api.example.com/list')
        .to_return(
          status: 200,
          body: '[{"id":1},{"id":2},{"id":3}]',
          headers: { 'Content-Type' => 'application/json' }
        )

      tool = registry.get('web_parse')
      result = tool.call(
        'url' => 'https://api.example.com/list',
        'json_path' => '0'
      )

      expect(result).to include('"id"')
      expect(result).to include('1')
      expect(result).not_to include('2')
    end

    it 'returns error when json_path not found' do
      stub_request(:get, 'https://api.example.com/data')
        .to_return(
          status: 200,
          body: '{"users":[]}',
          headers: { 'Content-Type' => 'application/json' }
        )

      tool = registry.get('web_parse')
      result = tool.call(
        'url' => 'https://api.example.com/data',
        'json_path' => 'nonexistent.field'
      )

      expect(result).to include('Error: JSON path')
      expect(result).to include('not found')
    end
  end

  describe 'XML parsing' do
    it 'returns XML content when format is xml' do
      xml_content = '<?xml version="1.0"?><root><item>test</item></root>'

      stub_request(:get, 'https://api.example.com/data.xml')
        .to_return(
          status: 200,
          body: xml_content,
          headers: { 'Content-Type' => 'application/xml' }
        )

      tool = registry.get('web_parse')
      result = tool.call('url' => 'https://api.example.com/data.xml')

      expect(result).to include('<root>')
      expect(result).to include('<item>')
    end

    it 'auto-detects XML from Content-Type' do
      stub_request(:get, 'https://api.example.com/feed')
        .to_return(
          status: 200,
          body: '<rss><channel><title>Test</title></channel></rss>',
          headers: { 'Content-Type' => 'text/xml' }
        )

      tool = registry.get('web_parse')
      result = tool.call('url' => 'https://api.example.com/feed')

      expect(result).to include('<rss>')
    end
  end

  describe 'text parsing' do
    it 'strips HTML and returns text when format is text' do
      html = '<html><body><h1>Title</h1><p>Content</p></body></html>'

      stub_request(:get, 'https://example.com/page')
        .to_return(
          status: 200,
          body: html,
          headers: { 'Content-Type' => 'text/html' }
        )

      tool = registry.get('web_parse')
      result = tool.call(
        'url' => 'https://example.com/page',
        'format' => 'text'
      )

      expect(result).to include('Title')
      expect(result).to include('Content')
      expect(result).not_to include('<html>')
      expect(result).not_to include('<body>')
    end

    it 'auto-detects text format for non-JSON/XML content' do
      stub_request(:get, 'https://example.com/plain')
        .to_return(
          status: 200,
          body: 'Plain text content',
          headers: { 'Content-Type' => 'text/plain' }
        )

      tool = registry.get('web_parse')
      result = tool.call('url' => 'https://example.com/plain')

      expect(result).to include('Plain text content')
    end
  end

  describe 'error handling' do
    it 'returns error for failed requests' do
      stub_request(:get, 'https://api.example.com/error')
        .to_return(status: 500, body: 'Server Error')

      tool = registry.get('web_parse')
      result = tool.call('url' => 'https://api.example.com/error')

      expect(result).to include('Error: Failed to fetch URL')
    end

    it 'returns error for empty response body' do
      stub_request(:get, 'https://api.example.com/empty')
        .to_return(status: 200, body: '')

      tool = registry.get('web_parse')
      result = tool.call('url' => 'https://api.example.com/empty')

      expect(result).to include('Error: Empty response body')
    end

    it 'returns error for unsupported format' do
      stub_request(:get, 'https://api.example.com/test')
        .to_return(status: 200, body: 'test')

      tool = registry.get('web_parse')
      result = tool.call(
        'url' => 'https://api.example.com/test',
        'format' => 'unsupported'
      )

      expect(result).to include('Error: Unsupported format')
    end

    it 'handles network errors' do
      stub_request(:get, 'https://api.example.com/timeout')
        .to_timeout

      tool = registry.get('web_parse')
      result = tool.call('url' => 'https://api.example.com/timeout')

      expect(result).to include('Error: Failed to fetch URL')
    end
  end

  describe 'URL validation' do
    it 'rejects URLs without http:// or https://' do
      tool = registry.get('web_parse')
      result = tool.call('url' => 'example.com')

      expect(result).to include('Error: Invalid URL')
    end

    it 'accepts http:// URLs' do
      stub_request(:get, 'http://api.example.com/data')
        .to_return(
          status: 200,
          body: '{"test":true}',
          headers: { 'Content-Type' => 'application/json' }
        )

      tool = registry.get('web_parse')
      result = tool.call('url' => 'http://api.example.com/data')

      expect(result).to include('"test"')
    end
  end
end
