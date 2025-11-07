require_relative '../spec_helper'

RSpec.describe 'Tool Loading Integration' do
  let(:registry) { LanguageOperator::Dsl::Registry.new }
  let(:tool_path) { File.expand_path('../../tools/k8s.rb', __dir__) }

  before do
    # Mock K8s::Client to avoid requiring actual cluster connection
    allow(K8s::Client).to receive(:in_cluster_config).and_return(double('K8s::Client'))
    allow(K8s::Client).to receive(:config).and_return(double('K8s::Client'))

    context = LanguageOperator::Dsl::Context.new(registry)
    code = File.read(tool_path)
    context.instance_eval(code, tool_path)
  end

  describe 'tool registration' do
    it 'loads all 6 k8s tools' do
      expect(registry.get('k8s_get')).not_to be_nil
      expect(registry.get('k8s_list')).not_to be_nil
      expect(registry.get('k8s_apply')).not_to be_nil
      expect(registry.get('k8s_delete')).not_to be_nil
      expect(registry.get('k8s_logs')).not_to be_nil
      expect(registry.get('k8s_exec')).not_to be_nil
    end

    it 'tools have correct metadata' do
      get_tool = registry.get('k8s_get')
      expect(get_tool.name).to eq('k8s_get')
      expect(get_tool.description).to include('Get a specific Kubernetes resource')

      list_tool = registry.get('k8s_list')
      expect(list_tool.name).to eq('k8s_list')
      expect(list_tool.description).to include('List Kubernetes resources')

      apply_tool = registry.get('k8s_apply')
      expect(apply_tool.name).to eq('k8s_apply')
      expect(apply_tool.description).to include('Create or update')

      delete_tool = registry.get('k8s_delete')
      expect(delete_tool.name).to eq('k8s_delete')
      expect(delete_tool.description).to include('Delete')

      logs_tool = registry.get('k8s_logs')
      expect(logs_tool.name).to eq('k8s_logs')
      expect(logs_tool.description).to include('logs')

      exec_tool = registry.get('k8s_exec')
      expect(exec_tool.name).to eq('k8s_exec')
      expect(exec_tool.description).to include('Execute')
    end
  end

  describe 'parameter definitions' do
    it 'k8s_get has required parameters' do
      tool = registry.get('k8s_get')
      params = tool.parameters

      resource_param = params['resource']
      expect(resource_param).not_to be_nil
      expect(resource_param.instance_variable_get(:@required)).to be true
      expect(resource_param.instance_variable_get(:@type)).to eq(:string)

      name_param = params['name']
      expect(name_param).not_to be_nil
      expect(name_param.instance_variable_get(:@required)).to be true
      expect(name_param.instance_variable_get(:@type)).to eq(:string)
    end

    it 'k8s_get has optional namespace parameter' do
      tool = registry.get('k8s_get')
      params = tool.parameters

      namespace_param = params['namespace']
      expect(namespace_param).not_to be_nil
      expect(namespace_param.instance_variable_get(:@required)).to be false
      expect(namespace_param.instance_variable_get(:@type)).to eq(:string)
    end

    it 'k8s_list has required resource parameter' do
      tool = registry.get('k8s_list')
      params = tool.parameters

      resource_param = params['resource']
      expect(resource_param).not_to be_nil
      expect(resource_param.instance_variable_get(:@required)).to be true
      expect(resource_param.instance_variable_get(:@type)).to eq(:string)
    end

    it 'k8s_logs has required name parameter' do
      tool = registry.get('k8s_logs')
      params = tool.parameters

      name_param = params['name']
      expect(name_param).not_to be_nil
      expect(name_param.instance_variable_get(:@required)).to be true
      expect(name_param.instance_variable_get(:@type)).to eq(:string)
    end

    it 'k8s_exec has required command parameter' do
      tool = registry.get('k8s_exec')
      params = tool.parameters

      command_param = params['command']
      expect(command_param).not_to be_nil
      expect(command_param.instance_variable_get(:@required)).to be true
      expect(command_param.instance_variable_get(:@type)).to eq(:string)
    end
  end
end
