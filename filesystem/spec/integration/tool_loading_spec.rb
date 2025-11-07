require_relative '../spec_helper'

RSpec.describe 'Tool Loading Integration' do
  let(:registry) { LanguageOperator::Dsl::Registry.new }
  let(:tool_path) { File.expand_path('../../tools/filesystem.rb', __dir__) }

  before do
    context = LanguageOperator::Dsl::Context.new(registry)
    code = File.read(tool_path)
    context.instance_eval(code, tool_path)
  end

  describe 'tool registration' do
    it 'loads all 6 filesystem tools' do
      expect(registry.get('read_file')).not_to be_nil
      expect(registry.get('write_file')).not_to be_nil
      expect(registry.get('list_directory')).not_to be_nil
      expect(registry.get('create_directory')).not_to be_nil
      expect(registry.get('get_file_info')).not_to be_nil
      expect(registry.get('search_files')).not_to be_nil
    end

    it 'tools have correct metadata' do
      read_tool = registry.get('read_file')
      expect(read_tool.name).to eq('read_file')
      expect(read_tool.description).to include('Read complete file')

      write_tool = registry.get('write_file')
      expect(write_tool.name).to eq('write_file')
      expect(write_tool.description).to include('Create new file')

      list_tool = registry.get('list_directory')
      expect(list_tool.name).to eq('list_directory')
      expect(list_tool.description).to include('List directory')

      create_tool = registry.get('create_directory')
      expect(create_tool.name).to eq('create_directory')
      expect(create_tool.description).to include('Create new directory')

      info_tool = registry.get('get_file_info')
      expect(info_tool.name).to eq('get_file_info')
      expect(info_tool.description).to include('Get detailed file')

      search_tool = registry.get('search_files')
      expect(search_tool.name).to eq('search_files')
      expect(search_tool.description).to include('search')
    end
  end

  describe 'parameter definitions' do
    it 'read_file has required path parameter' do
      tool = registry.get('read_file')
      params = tool.parameters

      path_param = params['path']
      expect(path_param).not_to be_nil
      expect(path_param.instance_variable_get(:@required)).to be true
      expect(path_param.instance_variable_get(:@type)).to eq(:string)
    end

    it 'read_file has optional head parameter' do
      tool = registry.get('read_file')
      params = tool.parameters

      head_param = params['head']
      expect(head_param).not_to be_nil
      expect(head_param.instance_variable_get(:@required)).to be false
      expect(head_param.instance_variable_get(:@type)).to eq(:number)
    end

    it 'write_file has required parameters' do
      tool = registry.get('write_file')
      params = tool.parameters

      path_param = params['path']
      expect(path_param).not_to be_nil
      expect(path_param.instance_variable_get(:@required)).to be true

      content_param = params['content']
      expect(content_param).not_to be_nil
      expect(content_param.instance_variable_get(:@required)).to be true
    end

    it 'search_files has pattern parameter' do
      tool = registry.get('search_files')
      params = tool.parameters

      pattern_param = params['pattern']
      expect(pattern_param).not_to be_nil
      expect(pattern_param.instance_variable_get(:@required)).to be true
      expect(pattern_param.instance_variable_get(:@type)).to eq(:string)
    end
  end
end
