require 'spec_helper'

RSpec.describe 'Filesystem Tools' do
  let(:registry) { load_filesystem_tools }

  describe 'Tool Loading' do
    it 'loads all 6 filesystem tools' do
      tools_count = ['read_file', 'write_file', 'list_directory', 'create_directory', 'get_file_info', 'search_files'].count do |name|
        registry.get(name) != nil
      end
      expect(tools_count).to eq(6)
    end

    it 'loads read_file tool with correct definition' do
      tool = registry.get('read_file')
      expect(tool).not_to be_nil
      expect(tool.description).to include('Read complete file')
      expect(tool.parameters.keys).to include('path')
      expect(tool.parameters.keys).to include('head')
      expect(tool.parameters.keys).to include('tail')
    end

    it 'loads write_file tool with correct definition' do
      tool = registry.get('write_file')
      expect(tool).not_to be_nil
      expect(tool.description).to include('Create new file')
      expect(tool.parameters.keys).to include('path')
      expect(tool.parameters.keys).to include('content')
    end

    it 'loads list_directory tool with correct definition' do
      tool = registry.get('list_directory')
      expect(tool).not_to be_nil
      expect(tool.description).to include('List directory contents')
      expect(tool.parameters.keys).to include('path')
    end

    it 'loads create_directory tool with correct definition' do
      tool = registry.get('create_directory')
      expect(tool).not_to be_nil
      expect(tool.description).to include('Create new directory')
      expect(tool.parameters.keys).to include('path')
    end

    it 'loads get_file_info tool with correct definition' do
      tool = registry.get('get_file_info')
      expect(tool).not_to be_nil
      expect(tool.description).to include('Get detailed file')
      expect(tool.parameters.keys).to include('path')
    end

    it 'loads search_files tool with correct definition' do
      tool = registry.get('search_files')
      expect(tool).not_to be_nil
      expect(tool.description).to include('search for files')
      expect(tool.parameters.keys).to include('path')
      expect(tool.parameters.keys).to include('pattern')
      expect(tool.parameters.keys).to include('max_results')
    end
  end

  describe 'Path validation (security)' do
    it 'rejects path traversal in read_file' do
      tool = registry.get('read_file')
      result = tool.call('path' => '../../../etc/passwd')
      expect(result).to include('Error')
      expect(result).to include('Access denied')
    end

    it 'rejects path traversal in write_file' do
      tool = registry.get('write_file')
      result = tool.call('path' => '../outside.txt', 'content' => 'bad')
      expect(result).to include('Error')
      expect(result).to include('Access denied')
    end

    it 'rejects path traversal in list_directory' do
      tool = registry.get('list_directory')
      result = tool.call('path' => '../../etc')
      expect(result).to include('Error')
      expect(result).to include('Access denied')
    end
  end
end
