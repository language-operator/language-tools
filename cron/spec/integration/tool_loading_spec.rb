require 'spec_helper'

RSpec.describe 'Cron Tool Loading Integration' do
  let(:registry) { load_cron_tools }
  let(:tool_names) { ['parse_cron', 'create_schedule', 'update_schedule', 'delete_schedule', 'list_schedules', 'get_next_runs', 'schedule_once'] }

  it 'loads all tools successfully' do
    tools_count = tool_names.count do |name|
      registry.get(name) != nil
    end
    expect(tools_count).to eq(7)
  end

  it 'all tools have descriptions' do
    tool_names.each do |name|
      tool = registry.get(name)
      expect(tool.description).not_to be_nil
      expect(tool.description).not_to be_empty
    end
  end

  it 'parse_cron tool works end-to-end' do
    tool = registry.get('parse_cron')
    result = tool.call('expression' => 'daily at 9am')
    expect(result).to include('Cron expression: 0 9 * * *')
    expect(result).to include('Next 5 occurrences:')
  end

  it 'get_next_runs tool works end-to-end' do
    tool = registry.get('get_next_runs')
    result = tool.call('schedule' => '0 12 * * *', 'count' => 3)
    expect(result).to include('Next 3 runs')
    expect(result).to include('0 12 * * *')
  end

  it 'handles errors gracefully' do
    tool = registry.get('parse_cron')
    result = tool.call('expression' => 'this is not valid')
    expect(result).to start_with('Error:')
  end
end
