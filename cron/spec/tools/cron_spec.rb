require 'spec_helper'

RSpec.describe 'Cron Tool' do
  let(:registry) { load_cron_tools }

  describe 'tool loading' do
    it 'registers all cron tools' do
      tool_names = ['parse_cron', 'create_schedule', 'update_schedule', 'delete_schedule', 'list_schedules', 'get_next_runs', 'schedule_once']
      tool_names.each do |name|
        expect(registry.get(name)).not_to be_nil
      end
    end

    it 'loads 7 tools total' do
      tools_count = ['parse_cron', 'create_schedule', 'update_schedule', 'delete_schedule', 'list_schedules', 'get_next_runs', 'schedule_once'].count do |name|
        registry.get(name) != nil
      end
      expect(tools_count).to eq(7)
    end
  end

  describe 'parse_cron tool' do
    let(:tool) { registry.get('parse_cron') }

    it 'has correct description' do
      expect(tool.description).to eq('Parse natural language or validate cron expression and return cron format')
    end

    it 'parses valid cron expression' do
      result = tool.call('expression' => '0 9 * * *')
      expect(result).to include('Cron expression: 0 9 * * *')
      expect(result).to include('Next 5 occurrences:')
    end

    it 'parses "hourly"' do
      result = tool.call('expression' => 'hourly')
      expect(result).to include('Cron expression: 0 * * * *')
    end

    it 'parses "daily"' do
      result = tool.call('expression' => 'daily')
      expect(result).to include('Cron expression: 0 0 * * *')
    end

    it 'parses "weekly"' do
      result = tool.call('expression' => 'weekly')
      expect(result).to include('Cron expression: 0 0 * * 0')
    end

    it 'parses "daily at 9am"' do
      result = tool.call('expression' => 'daily at 9am')
      expect(result).to include('Cron expression: 0 9 * * *')
    end

    it 'parses "every Monday"' do
      result = tool.call('expression' => 'every Monday')
      expect(result).to include('Cron expression: 0 0 * * 1')
    end

    it 'parses "weekdays"' do
      result = tool.call('expression' => 'weekdays')
      expect(result).to include('Cron expression: 0 0 * * 1-5')
    end

    it 'parses "every 5 minutes"' do
      result = tool.call('expression' => 'every 5 minutes')
      expect(result).to include('Cron expression: */5 * * * *')
    end

    it 'parses "Monday at 2pm"' do
      result = tool.call('expression' => 'Monday at 2pm')
      expect(result).to include('Cron expression: 0 14 * * 1')
    end

    it 'returns error for invalid expression' do
      result = tool.call('expression' => 'invalid nonsense')
      expect(result).to start_with('Error:')
    end
  end

  describe 'get_next_runs tool' do
    let(:tool) { registry.get('get_next_runs') }

    it 'has correct description' do
      expect(tool.description).to eq('Get the next N execution times for a cron expression')
    end

    it 'returns next 5 runs by default' do
      result = tool.call('schedule' => '0 9 * * *')
      expect(result).to include('Next 5 runs')
      expect(result.scan(/\d+\.\s+\d{4}-\d{2}-\d{2}/).count).to eq(5)
    end

    it 'returns custom number of runs' do
      result = tool.call('schedule' => '0 9 * * *', 'count' => 3)
      expect(result).to include('Next 3 runs')
      expect(result.scan(/\d+\.\s+\d{4}-\d{2}-\d{2}/).count).to eq(3)
    end

    it 'parses natural language' do
      result = tool.call('schedule' => 'daily at noon', 'count' => 2)
      expect(result).to include('Next 2 runs')
      expect(result).to include('0 12 * * *')
    end

    it 'limits to max 20 runs' do
      result = tool.call('schedule' => '0 * * * *', 'count' => 100)
      expect(result.scan(/\d+\.\s+\d{4}-\d{2}-\d{2}/).count).to eq(20)
    end

    it 'returns error for invalid schedule' do
      result = tool.call('schedule' => 'invalid')
      expect(result).to start_with('Error:')
    end
  end

  describe 'create_schedule tool' do
    let(:tool) { registry.get('create_schedule') }

    it 'has required parameters' do
      expect(tool.parameters['agent_name']).not_to be_nil
      expect(tool.parameters['schedule']).not_to be_nil
      expect(tool.parameters['task']).not_to be_nil
    end
  end

  describe 'update_schedule tool' do
    let(:tool) { registry.get('update_schedule') }

    it 'has required parameters' do
      expect(tool.parameters['agent_name']).not_to be_nil
    end
  end

  describe 'delete_schedule tool' do
    let(:tool) { registry.get('delete_schedule') }

    it 'has required parameters' do
      expect(tool.parameters['agent_name']).not_to be_nil
    end
  end

  describe 'list_schedules tool' do
    let(:tool) { registry.get('list_schedules') }

    it 'has required parameters' do
      expect(tool.parameters['agent_name']).not_to be_nil
    end
  end

  describe 'schedule_once tool' do
    let(:tool) { registry.get('schedule_once') }

    it 'has required parameters' do
      expect(tool.parameters['agent_name']).not_to be_nil
      expect(tool.parameters['delay']).not_to be_nil
      expect(tool.parameters['task']).not_to be_nil
    end
  end
end
