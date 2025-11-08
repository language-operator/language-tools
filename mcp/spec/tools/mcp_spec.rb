require_relative '../spec_helper'

RSpec.describe 'MCP Tools' do
  let(:registry) { load_mcp_tools }

  describe 'Tool Loading' do
    it 'loads all 4 MCP tools' do
      tools_count = ['mcp_discover', 'mcp_list_tools', 'mcp_call', 'mcp_server_info'].count do |name|
        registry.get(name) != nil
      end
      expect(tools_count).to eq(4)
    end

    it 'loads mcp_discover tool with correct definition' do
      tool = registry.get('mcp_discover')
      expect(tool).not_to be_nil
      expect(tool.description).to include('Discover MCP servers')
      expect(tool.parameters.keys).to be_empty
    end

    it 'loads mcp_list_tools tool with correct definition' do
      tool = registry.get('mcp_list_tools')
      expect(tool).not_to be_nil
      expect(tool.description).to include('List all tools')
      expect(tool.parameters.keys).to include('server')
    end

    it 'loads mcp_call tool with correct definition' do
      tool = registry.get('mcp_call')
      expect(tool).not_to be_nil
      expect(tool.description).to include('Call a tool')
      expect(tool.parameters.keys).to include('server')
      expect(tool.parameters.keys).to include('tool')
      expect(tool.parameters.keys).to include('arguments')
    end

    it 'loads mcp_server_info tool with correct definition' do
      tool = registry.get('mcp_server_info')
      expect(tool).not_to be_nil
      expect(tool.description).to include('information about an MCP server')
      expect(tool.parameters.keys).to include('server')
    end
  end

  describe 'Parameter Definitions' do
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
