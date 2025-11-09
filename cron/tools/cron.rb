require 'rufus-scheduler'
require 'chronic'
require 'k8s-ruby'
require 'json'
require 'language_operator'

# Helper module for cron operations
module CronHelpers
  # Parse natural language to cron expression
  def self.parse_to_cron(input)
    # First try parsing as a cron expression
    return input if valid_cron?(input)

    # Try common patterns
    case input.downcase.strip
    when 'hourly', 'every hour'
      '0 * * * *'
    when 'daily', 'every day'
      '0 0 * * *'
    when 'weekly', 'every week'
      '0 0 * * 0'
    when 'monthly', 'every month'
      '0 0 1 * *'
    when /every (\d+) (minute|minutes)/
      interval = Regexp.last_match(1).to_i
      return "Error: Interval must be between 1 and 59" if interval < 1 || interval > 59
      "*/#{interval} * * * *"
    when /every (\d+) (hour|hours)/
      interval = Regexp.last_match(1).to_i
      return "Error: Interval must be between 1 and 23" if interval < 1 || interval > 23
      "0 */#{interval} * * *"
    when /every (\d+) (day|days)/
      interval = Regexp.last_match(1).to_i
      return "Error: Interval must be between 1 and 31" if interval < 1 || interval > 31
      "0 0 */#{interval} * *"
    when /^(monday|tuesday|wednesday|thursday|friday|saturday|sunday)s?$/i
      day = day_to_number(Regexp.last_match(1))
      "0 0 * * #{day}"
    when /every (monday|tuesday|wednesday|thursday|friday|saturday|sunday)/i
      day = day_to_number(Regexp.last_match(1))
      "0 0 * * #{day}"
    when /weekdays?/i
      '0 0 * * 1-5'
    when /weekends?/i
      '0 0 * * 0,6'
    when /(daily|every day) at noon/i
      '0 12 * * *'
    when /(daily|every day) at midnight/i
      '0 0 * * *'
    when /at noon/i
      '0 12 * * *'
    when /at midnight/i
      '0 0 * * *'
    when /(monday|tuesday|wednesday|thursday|friday|saturday|sunday) at (\d{1,2}):?(\d{2})?\s*(am|pm)?/i
      day = day_to_number(Regexp.last_match(1))
      hour, min = parse_time(Regexp.last_match(2), Regexp.last_match(3), Regexp.last_match(4))
      "#{min} #{hour} * * #{day}"
    when /(daily|every day) at (\d{1,2}):?(\d{2})?\s*(am|pm)?/i
      hour, min = parse_time(Regexp.last_match(2), Regexp.last_match(3), Regexp.last_match(4))
      "#{min} #{hour} * * *"
    when /at (\d{1,2}):?(\d{2})?\s*(am|pm)?/i
      hour, min = parse_time(Regexp.last_match(1), Regexp.last_match(2), Regexp.last_match(3))
      "#{min} #{hour} * * *"
    else
      "Error: Could not parse '#{input}' into a cron expression. Try a cron expression like '0 9 * * *' or natural language like 'daily at 9am'"
    end
  end

  # Validate cron expression
  def self.valid_cron?(expression)
    return false unless expression.is_a?(String)
    # Check if it looks like a cron expression (5 fields with spaces/asterisks/numbers)
    return false unless expression.match?(/^[\d\*\-,\/]+\s+[\d\*\-,\/]+\s+[\d\*\-,\/]+\s+[\d\*\-,\/]+\s+[\d\*\-,\/]+$/)
    Rufus::Scheduler.parse(expression)
    true
  rescue ArgumentError
    false
  end

  # Parse time components
  def self.parse_time(hour_str, min_str, meridian)
    hour = hour_str.to_i
    min = min_str ? min_str.to_i : 0

    if meridian&.downcase == 'pm' && hour != 12
      hour += 12
    elsif meridian&.downcase == 'am' && hour == 12
      hour = 0
    end

    [hour, min]
  end

  # Convert day name to number (0 = Sunday)
  def self.day_to_number(day_name)
    days = {
      'sunday' => 0,
      'monday' => 1,
      'tuesday' => 2,
      'wednesday' => 3,
      'thursday' => 4,
      'friday' => 5,
      'saturday' => 6
    }
    days[day_name.downcase] || 0
  end

  # Get next N run times
  def self.get_next_times(cron_expression, count = 5)
    return ["Error: Invalid cron expression"] unless valid_cron?(cron_expression)

    cronline = Rufus::Scheduler.parse(cron_expression)
    times = []
    time = Time.now

    count.times do
      time = cronline.next_time(time)
      times << time.utc.strftime('%Y-%m-%d %H:%M:%S UTC')
    end

    times
  rescue StandardError => e
    ["Error: #{e.message}"]
  end

  # Parse delay string to seconds
  def self.parse_delay(delay_str)
    case delay_str.downcase.strip
    when /^(\d+)\s*(second|seconds|sec|s)$/
      Regexp.last_match(1).to_i
    when /^(\d+)\s*(minute|minutes|min|m)$/
      Regexp.last_match(1).to_i * 60
    when /^(\d+)\s*(hour|hours|hr|h)$/
      Regexp.last_match(1).to_i * 3600
    when /^(\d+)\s*(day|days|d)$/
      Regexp.last_match(1).to_i * 86400
    else
      nil
    end
  end

end

# Parse natural language or cron expression to cron format
tool "parse_cron" do
  description "Parse natural language or validate cron expression and return cron format"

  parameter "expression" do
    type :string
    required true
    description "Natural language (e.g., 'daily at 9am', 'every Monday') or cron expression (e.g., '0 9 * * *')"
  end

  execute do |params|
    result = CronHelpers.parse_to_cron(params['expression'])

    if result.start_with?('Error:')
      result
    else
      "Cron expression: #{result}\nDescription: Runs at the specified schedule\nNext 5 occurrences:\n#{CronHelpers.get_next_times(result).join("\n")}"
    end
  end
end

# Create a schedule on a LanguageAgent
tool "create_schedule" do
  description "Create a new schedule on a LanguageAgent CRD"

  parameter "agent_name" do
    type :string
    required true
    description "Name of the LanguageAgent resource"
  end

  parameter "namespace" do
    type :string
    required false
    default "default"
    description "Kubernetes namespace"
  end

  parameter "schedule" do
    type :string
    required true
    description "Cron expression or natural language (e.g., 'daily at 9am')"
  end

  parameter "task" do
    type :string
    required true
    description "Task description or prompt to execute on schedule"
  end

  parameter "name" do
    type :string
    required false
    description "Optional name for this schedule entry"
  end

  execute do |params|
    # Parse schedule
    cron_expr = CronHelpers.parse_to_cron(params['schedule'])
    next cron_expr if cron_expr.start_with?('Error:')

    begin
      client = LanguageOperator::Kubernetes::Client.instance
      agent_api = client.api('langop.io/v1alpha1')

      # Get current agent
      agent = agent_api.resource('languageagents', namespace: params['namespace']).get(params['agent_name'])

      # Initialize schedules array if not exists
      agent.spec['schedules'] ||= []

      # Create schedule entry
      schedule_entry = {
        'cron' => cron_expr,
        'task' => params['task']
      }
      schedule_entry['name'] = params['name'] if params['name']

      # Add to schedules
      agent.spec['schedules'] << schedule_entry

      # Update the agent
      agent_api.resource('languageagents', namespace: params['namespace']).update_resource(agent)

      "Schedule created successfully:\nAgent: #{params['agent_name']}\nCron: #{cron_expr}\nTask: #{params['task']}\nNext run: #{CronHelpers.get_next_times(cron_expr, 1).first}"
    rescue K8s::Error::NotFound
      LanguageOperator::Errors.not_found("LanguageAgent '#{params['agent_name']}'", "namespace '#{params['namespace']}'")
    rescue StandardError => e
      "Error: #{e.message}"
    end
  end
end

# Update an existing schedule
tool "update_schedule" do
  description "Update an existing schedule on a LanguageAgent"

  parameter "agent_name" do
    type :string
    required true
    description "Name of the LanguageAgent resource"
  end

  parameter "namespace" do
    type :string
    required false
    default "default"
    description "Kubernetes namespace"
  end

  parameter "schedule_index" do
    type :number
    required false
    description "Index of the schedule to update (0-based)"
  end

  parameter "schedule_name" do
    type :string
    required false
    description "Name of the schedule to update"
  end

  parameter "new_schedule" do
    type :string
    required false
    description "New cron expression or natural language"
  end

  parameter "new_task" do
    type :string
    required false
    description "New task description"
  end

  execute do |params|
    next "Error: Must specify either schedule_index or schedule_name" unless params['schedule_index'] || params['schedule_name']
    next "Error: Must specify new_schedule or new_task" unless params['new_schedule'] || params['new_task']

    # Parse new schedule if provided
    cron_expr = nil
    if params['new_schedule']
      cron_expr = CronHelpers.parse_to_cron(params['new_schedule'])
      next cron_expr if cron_expr.start_with?('Error:')
    end

    begin
      client = LanguageOperator::Kubernetes::Client.instance
      agent_api = client.api('langop.io/v1alpha1')

      agent = agent_api.resource('languageagents', namespace: params['namespace']).get(params['agent_name'])

      next "Error: No schedules found on agent" if agent.spec['schedules'].nil? || agent.spec['schedules'].empty?

      # Find schedule index
      index = if params['schedule_index']
                params['schedule_index'].to_i
              else
                agent.spec['schedules'].find_index { |s| s['name'] == params['schedule_name'] }
              end

      next "Error: Schedule not found" if index.nil? || index >= agent.spec['schedules'].length

      # Update schedule
      agent.spec['schedules'][index]['cron'] = cron_expr if cron_expr
      agent.spec['schedules'][index]['task'] = params['new_task'] if params['new_task']

      agent_api.resource('languageagents', namespace: params['namespace']).update_resource(agent)

      updated = agent.spec['schedules'][index]
      "Schedule updated successfully:\nAgent: #{params['agent_name']}\nCron: #{updated['cron']}\nTask: #{updated['task']}\nNext run: #{CronHelpers.get_next_times(updated['cron'], 1).first}"
    rescue K8s::Error::NotFound
      LanguageOperator::Errors.not_found("LanguageAgent '#{params['agent_name']}'", "namespace '#{params['namespace']}'")
    rescue StandardError => e
      "Error: #{e.message}"
    end
  end
end

# Delete a schedule
tool "delete_schedule" do
  description "Delete a schedule from a LanguageAgent"

  parameter "agent_name" do
    type :string
    required true
    description "Name of the LanguageAgent resource"
  end

  parameter "namespace" do
    type :string
    required false
    default "default"
    description "Kubernetes namespace"
  end

  parameter "schedule_index" do
    type :number
    required false
    description "Index of the schedule to delete (0-based)"
  end

  parameter "schedule_name" do
    type :string
    required false
    description "Name of the schedule to delete"
  end

  execute do |params|
    next "Error: Must specify either schedule_index or schedule_name" unless params['schedule_index'] || params['schedule_name']

    begin
      client = LanguageOperator::Kubernetes::Client.instance
      agent_api = client.api('langop.io/v1alpha1')

      agent = agent_api.resource('languageagents', namespace: params['namespace']).get(params['agent_name'])

      next "Error: No schedules found on agent" if agent.spec['schedules'].nil? || agent.spec['schedules'].empty?

      # Find schedule index
      index = if params['schedule_index']
                params['schedule_index'].to_i
              else
                agent.spec['schedules'].find_index { |s| s['name'] == params['schedule_name'] }
              end

      next "Error: Schedule not found" if index.nil? || index >= agent.spec['schedules'].length

      deleted = agent.spec['schedules'].delete_at(index)

      agent_api.resource('languageagents', namespace: params['namespace']).update_resource(agent)

      "Schedule deleted successfully:\nAgent: #{params['agent_name']}\nDeleted schedule: #{deleted['cron']} - #{deleted['task']}"
    rescue K8s::Error::NotFound
      LanguageOperator::Errors.not_found("LanguageAgent '#{params['agent_name']}'", "namespace '#{params['namespace']}'")
    rescue StandardError => e
      "Error: #{e.message}"
    end
  end
end

# List all schedules for an agent
tool "list_schedules" do
  description "List all schedules for a LanguageAgent"

  parameter "agent_name" do
    type :string
    required true
    description "Name of the LanguageAgent resource"
  end

  parameter "namespace" do
    type :string
    required false
    default "default"
    description "Kubernetes namespace"
  end

  execute do |params|
    begin
      client = LanguageOperator::Kubernetes::Client.instance
      agent_api = client.api('langop.io/v1alpha1')

      agent = agent_api.resource('languageagents', namespace: params['namespace']).get(params['agent_name'])

      schedules = agent.spec['schedules']

      if schedules.nil? || schedules.empty?
        next "No schedules found for agent '#{params['agent_name']}'"
      end

      result = "Schedules for #{params['agent_name']}:\n\n"
      schedules.each_with_index do |schedule, idx|
        result += "#{idx}. "
        result += "[#{schedule['name']}] " if schedule['name']
        result += "#{schedule['cron']}\n"
        result += "   Task: #{schedule['task']}\n"
        result += "   Next run: #{CronHelpers.get_next_times(schedule['cron'], 1).first}\n\n"
      end

      result
    rescue K8s::Error::NotFound
      LanguageOperator::Errors.not_found("LanguageAgent '#{params['agent_name']}'", "namespace '#{params['namespace']}'")
    rescue StandardError => e
      "Error: #{e.message}"
    end
  end
end

# Get next run times for a schedule
tool "get_next_runs" do
  description "Get the next N execution times for a cron expression"

  parameter "schedule" do
    type :string
    required true
    description "Cron expression or natural language"
  end

  parameter "count" do
    type :number
    required false
    default 5
    description "Number of upcoming runs to show (default: 5)"
  end

  execute do |params|
    cron_expr = CronHelpers.parse_to_cron(params['schedule'])
    next cron_expr if cron_expr.start_with?('Error:')

    count = [params['count'].to_i, 1].max
    count = [count, 20].min # Max 20

    times = CronHelpers.get_next_times(cron_expr, count)
    next times.first if times.first.start_with?('Error:')

    "Next #{count} runs for '#{cron_expr}':\n#{times.map.with_index { |t, i| "#{i + 1}. #{t}" }.join("\n")}"
  end
end

# Schedule a one-time delayed execution
tool "schedule_once" do
  description "Schedule a one-time task execution after a delay"

  parameter "agent_name" do
    type :string
    required true
    description "Name of the LanguageAgent resource"
  end

  parameter "namespace" do
    type :string
    required false
    default "default"
    description "Kubernetes namespace"
  end

  parameter "delay" do
    type :string
    required true
    description "Delay before execution (e.g., '5 minutes', '2 hours', '1 day')"
  end

  parameter "task" do
    type :string
    required true
    description "Task description or prompt to execute"
  end

  parameter "name" do
    type :string
    required false
    description "Optional name for this scheduled task"
  end

  execute do |params|
    # Parse delay
    seconds = CronHelpers.parse_delay(params['delay'])
    next "Error: Could not parse delay '#{params['delay']}'. Use format like '5 minutes', '2 hours', '1 day'" unless seconds

    # Calculate execution time
    execute_at = Time.now + seconds

    # Create a cron expression for the specific time (runs once)
    # Format: minute hour day month year
    cron_expr = execute_at.strftime('%M %H %d %m *')

    begin
      client = LanguageOperator::Kubernetes::Client.instance
      agent_api = client.api('langop.io/v1alpha1')

      agent = agent_api.resource('languageagents', namespace: params['namespace']).get(params['agent_name'])

      agent.spec['schedules'] ||= []

      schedule_entry = {
        'cron' => cron_expr,
        'task' => params['task'],
        'once' => true # Mark as one-time execution
      }
      schedule_entry['name'] = params['name'] if params['name']

      agent.spec['schedules'] << schedule_entry

      agent_api.resource('languageagents', namespace: params['namespace']).update_resource(agent)

      "One-time schedule created successfully:\nAgent: #{params['agent_name']}\nExecute at: #{execute_at.utc.strftime('%Y-%m-%d %H:%M:%S UTC')}\nTask: #{params['task']}"
    rescue K8s::Error::NotFound
      LanguageOperator::Errors.not_found("LanguageAgent '#{params['agent_name']}'", "namespace '#{params['namespace']}'")
    rescue StandardError => e
      "Error: #{e.message}"
    end
  end
end
