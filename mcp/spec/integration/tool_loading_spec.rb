require_relative '../spec_helper'

RSpec.describe 'Tool Loading Integration' do
  let(:registry) { LanguageOperator::Dsl::Registry.new }
  let(:tool_path) { File.expand_path('../../tools/mcp.rb', __dir__) }

  before do
    context = LanguageOperator::Dsl::Context.new(registry)
    code = File.read(tool_path)
    context.instance_eval(code, tool_path)
  end

  describe 'tool registration' do
    it 'loads all 4 MCP tools' do
      expect(registry.get('mcp_discover')).not_to be_nil
      expect(registry.get('mcp_list_tools')).not_to be_nil
      expect(registry.get('mcp_call')).not_to be_nil
      expect(registry.get('mcp_server_info')).not_to be_nil
    end

    it 'tools have correct metadata' do
      discover_tool = registry.get('mcp_discover')
      expect(discover_tool.name).to eq('mcp_discover')
      expect(discover_tool.description).to include('Discover MCP servers')

      list_tool = registry.get('mcp_list_tools')
      expect(list_tool.name).to eq('mcp_list_tools')
      expect(list_tool.description).to include('List all tools')

      call_tool = registry.get('mcp_call')
      expect(call_tool.name).to eq('mcp_call')
      expect(call_tool.description).to include('Call a tool')

      info_tool = registry.get('mcp_server_info')
      expect(info_tool.name).to eq('mcp_server_info')
      expect(info_tool.description).to include('information about an MCP server')
    end
  end

  describe 'parameter definitions' do
    it 'mcp_discover has no required parameters' do
      tool = registry.get('mcp_discover')
      params = tool.parameters

      expect(params).to be_empty
    end

    it 'mcp_list_tools has required server parameter' do
      tool = registry.get('mcp_list_tools')
      params = tool.parameters

      server_param = params['server']
      expect(server_param).not_to be_nil
      expect(server_param.instance_variable_get(:@required)).to be true
      expect(server_param.instance_variable_get(:@type)).to eq(:string)
    end

    it 'mcp_call has required server and tool parameters' do
      tool = registry.get('mcp_call')
      params = tool.parameters

      server_param = params['server']
      expect(server_param).not_to be_nil
      expect(server_param.instance_variable_get(:@required)).to be true
      expect(server_param.instance_variable_get(:@type)).to eq(:string)

      tool_param = params['tool']
      expect(tool_param).not_to be_nil
      expect(tool_param.instance_variable_get(:@required)).to be true
      expect(tool_param.instance_variable_get(:@type)).to eq(:string)
    end

    it 'mcp_call has optional arguments parameter' do
      tool = registry.get('mcp_call')
      params = tool.parameters

      args_param = params['arguments']
      expect(args_param).not_to be_nil
      expect(args_param.instance_variable_get(:@required)).to be false
      expect(args_param.instance_variable_get(:@type)).to eq(:object)
    end

    it 'mcp_server_info has required server parameter' do
      tool = registry.get('mcp_server_info')
      params = tool.parameters

      server_param = params['server']
      expect(server_param).not_to be_nil
      expect(server_param.instance_variable_get(:@required)).to be true
      expect(server_param.instance_variable_get(:@type)).to eq(:string)
    end
  end
end
