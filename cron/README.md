# Cron Tool

**Self-scheduling and temporal operations for autonomous agents**

The Cron Tool enables Language Operator agents to schedule their own tasks, create recurring workflows, and manage time-based automation through natural language scheduling.

## Overview

- **Type:** MCP Server
- **Deployment Mode:** Service
- **Port:** 80
- **Purpose:** Agent self-scheduling and cron management
- **Natural Language:** Supports human-readable schedule expressions
- **CRD Integration:** Directly modifies LanguageAgent schedules
- **Protocol:** MCP 2024-11-05

## Use Cases

### Recurring Reports
```yaml
apiVersion: langop.io/v1alpha1
kind: LanguageAgent
metadata:
  name: daily-reporter
spec:
  instructions: |
    When scheduled, generate and email daily summary reports
  tools:
  - cron
  - workspace
  - email
```

**Perfect for:**
- Daily/weekly summaries
- Automated backups
- Periodic health checks
- Scheduled notifications

### Self-Healing Workflows
```yaml
apiVersion: langop.io/v1alpha1
kind: LanguageAgent
metadata:
  name: self-monitor
spec:
  instructions: |
    Use cron to schedule hourly health checks.
    If issues detected, schedule follow-up check in 5 minutes.
  tools:
  - cron
  - k8s
  - email
```

**Perfect for:**
- Automated monitoring
- Self-healing systems
- Retry logic
- Escalation workflows

### Time-Based Automation
```yaml
apiVersion: langop.io/v1alpha1
kind: LanguageAgent
metadata:
  name: scheduler
spec:
  instructions: |
    Schedule deployments during maintenance windows.
    Run cleanup tasks weekly.
  tools:
  - cron
  - k8s
  - workspace
```

**Perfect for:**
- Maintenance windows
- Scheduled deployments
- Cleanup tasks
- Business hour operations

### Dynamic Scheduling
```yaml
apiVersion: langop.io/v1alpha1
kind: LanguageAgent
metadata:
  name: adaptive-scheduler
spec:
  instructions: |
    Adjust your own schedule based on system load.
    Schedule tasks dynamically as needed.
  tools:
  - cron
  - k8s
```

**Perfect for:**
- Adaptive scheduling
- Load-based automation
- Dynamic workflows
- Event-driven tasks

---

## Tools

The Cron Tool exposes 7 MCP tools for schedule management:

### 1. parse_cron

Parse natural language or validate cron expression and return cron format.

**Parameters:**
- `expression` (string, required) - Natural language (e.g., 'daily at 9am', 'every Monday') or cron expression (e.g., '0 9 * * *')

**Returns:** Validated cron expression with next 5 execution times

**Examples:**

Parse natural language:
```json
{
  "name": "parse_cron",
  "arguments": {
    "expression": "daily at 9am"
  }
}
```

Validate cron expression:
```json
{
  "name": "parse_cron",
  "arguments": {
    "expression": "0 9 * * *"
  }
}
```

Parse complex schedule:
```json
{
  "name": "parse_cron",
  "arguments": {
    "expression": "every Monday at 2pm"
  }
}
```

Parse interval:
```json
{
  "name": "parse_cron",
  "arguments": {
    "expression": "every 15 minutes"
  }
}
```

**Supported Natural Language Patterns:**

| Pattern | Cron Expression | Description |
|---------|----------------|-------------|
| `hourly` | `0 * * * *` | Every hour on the hour |
| `daily` | `0 0 * * *` | Every day at midnight |
| `weekly` | `0 0 * * 0` | Every Sunday at midnight |
| `monthly` | `0 0 1 * *` | First day of month at midnight |
| `every N minutes` | `*/N * * * *` | Every N minutes (1-59) |
| `every N hours` | `0 */N * * *` | Every N hours (1-23) |
| `every N days` | `0 0 */N * *` | Every N days (1-31) |
| `Monday` | `0 0 * * 1` | Every Monday at midnight |
| `weekdays` | `0 0 * * 1-5` | Monday-Friday at midnight |
| `weekends` | `0 0 * * 0,6` | Saturday-Sunday at midnight |
| `daily at noon` | `0 12 * * *` | Every day at 12:00 PM |
| `daily at midnight` | `0 0 * * *` | Every day at 00:00 |
| `Monday at 2pm` | `0 14 * * 1` | Every Monday at 2:00 PM |
| `daily at 9:30am` | `30 9 * * *` | Every day at 9:30 AM |

**Output Format:**
```
Cron expression: 0 9 * * *
Description: Runs at the specified schedule
Next 5 occurrences:
2025-01-16 09:00:00 UTC
2025-01-17 09:00:00 UTC
2025-01-18 09:00:00 UTC
2025-01-19 09:00:00 UTC
2025-01-20 09:00:00 UTC
```

For intervals:
```
Cron expression: */15 * * * *
Description: Runs at the specified schedule
Next 5 occurrences:
2025-01-15 14:15:00 UTC
2025-01-15 14:30:00 UTC
2025-01-15 14:45:00 UTC
2025-01-15 15:00:00 UTC
2025-01-15 15:15:00 UTC
```

**Error Handling:**
- Invalid expression → `Error: Could not parse 'xyz' into a cron expression. Try a cron expression like '0 9 * * *' or natural language like 'daily at 9am'`
- Invalid interval → `Error: Interval must be between 1 and 59`

---

### 2. create_schedule

Create a new schedule on a LanguageAgent CRD.

**Parameters:**
- `agent_name` (string, required) - Name of the LanguageAgent resource
- `namespace` (string, optional) - Kubernetes namespace (default: "default")
- `schedule` (string, required) - Cron expression or natural language (e.g., 'daily at 9am')
- `task` (string, required) - Task description or prompt to execute on schedule
- `name` (string, optional) - Optional name for this schedule entry

**Returns:** Success message with next execution time

**Examples:**

Create daily schedule:
```json
{
  "name": "create_schedule",
  "arguments": {
    "agent_name": "reporter",
    "schedule": "daily at 9am",
    "task": "Generate and email daily summary report"
  }
}
```

Create named schedule:
```json
{
  "name": "create_schedule",
  "arguments": {
    "agent_name": "monitor",
    "namespace": "production",
    "schedule": "every 5 minutes",
    "task": "Check system health and alert if issues detected",
    "name": "health-check"
  }
}
```

Create weekly schedule:
```json
{
  "name": "create_schedule",
  "arguments": {
    "agent_name": "cleanup",
    "schedule": "Sunday at midnight",
    "task": "Clean up old logs and temporary files"
  }
}
```

**Output Format:**
```
Schedule created successfully:
Agent: reporter
Cron: 0 9 * * *
Task: Generate and email daily summary report
Next run: 2025-01-16 09:00:00 UTC
```

**Error Handling:**
- Agent not found → `Error: LanguageAgent 'reporter' not found in namespace 'default'`
- Invalid schedule → `Error: Could not parse 'xyz' into a cron expression...`
- Permission denied → `Error: <RBAC error details>`

---

### 3. update_schedule

Update an existing schedule on a LanguageAgent.

**Parameters:**
- `agent_name` (string, required) - Name of the LanguageAgent resource
- `namespace` (string, optional) - Kubernetes namespace (default: "default")
- `schedule_index` (number, optional) - Index of the schedule to update (0-based)
- `schedule_name` (string, optional) - Name of the schedule to update
- `new_schedule` (string, optional) - New cron expression or natural language
- `new_task` (string, optional) - New task description

**Note:** Must specify either `schedule_index` or `schedule_name`. Must specify either `new_schedule` or `new_task`.

**Returns:** Success message with updated schedule details

**Examples:**

Update schedule by index:
```json
{
  "name": "update_schedule",
  "arguments": {
    "agent_name": "reporter",
    "schedule_index": 0,
    "new_schedule": "daily at 10am"
  }
}
```

Update schedule by name:
```json
{
  "name": "update_schedule",
  "arguments": {
    "agent_name": "monitor",
    "schedule_name": "health-check",
    "new_schedule": "every 10 minutes"
  }
}
```

Update task only:
```json
{
  "name": "update_schedule",
  "arguments": {
    "agent_name": "cleanup",
    "schedule_index": 0,
    "new_task": "Clean up old logs and archive to workspace"
  }
}
```

Update both:
```json
{
  "name": "update_schedule",
  "arguments": {
    "agent_name": "reporter",
    "schedule_name": "daily-report",
    "new_schedule": "weekdays at 9am",
    "new_task": "Generate business-day report and email to team"
  }
}
```

**Output Format:**
```
Schedule updated successfully:
Agent: reporter
Cron: 0 10 * * *
Task: Generate and email daily summary report
Next run: 2025-01-16 10:00:00 UTC
```

**Error Handling:**
- No identifier → `Error: Must specify either schedule_index or schedule_name`
- No update → `Error: Must specify new_schedule or new_task`
- Schedule not found → `Error: Schedule not found`
- Agent not found → `Error: LanguageAgent 'reporter' not found in namespace 'default'`

---

### 4. delete_schedule

Delete a schedule from a LanguageAgent.

**Parameters:**
- `agent_name` (string, required) - Name of the LanguageAgent resource
- `namespace` (string, optional) - Kubernetes namespace (default: "default")
- `schedule_index` (number, optional) - Index of the schedule to delete (0-based)
- `schedule_name` (string, optional) - Name of the schedule to delete

**Note:** Must specify either `schedule_index` or `schedule_name`.

**Returns:** Success message with deleted schedule details

**Examples:**

Delete by index:
```json
{
  "name": "delete_schedule",
  "arguments": {
    "agent_name": "reporter",
    "schedule_index": 0
  }
}
```

Delete by name:
```json
{
  "name": "delete_schedule",
  "arguments": {
    "agent_name": "monitor",
    "schedule_name": "health-check"
  }
}
```

**Output Format:**
```
Schedule deleted successfully:
Agent: reporter
Deleted schedule: 0 9 * * * - Generate and email daily summary report
```

**Error Handling:**
- No identifier → `Error: Must specify either schedule_index or schedule_name`
- Schedule not found → `Error: Schedule not found`
- No schedules → `Error: No schedules found on agent`
- Agent not found → `Error: LanguageAgent 'reporter' not found in namespace 'default'`

---

### 5. list_schedules

List all schedules for a LanguageAgent.

**Parameters:**
- `agent_name` (string, required) - Name of the LanguageAgent resource
- `namespace` (string, optional) - Kubernetes namespace (default: "default")

**Returns:** List of all schedules with next execution times

**Examples:**

List schedules:
```json
{
  "name": "list_schedules",
  "arguments": {
    "agent_name": "reporter"
  }
}
```

List in different namespace:
```json
{
  "name": "list_schedules",
  "arguments": {
    "agent_name": "monitor",
    "namespace": "production"
  }
}
```

**Output Format:**
```
Schedules for reporter:

0. [daily-report] 0 9 * * *
   Task: Generate and email daily summary report
   Next run: 2025-01-16 09:00:00 UTC

1. [weekly-backup] 0 0 * * 0
   Task: Backup workspace to external storage
   Next run: 2025-01-19 00:00:00 UTC

2. */15 * * * *
   Task: Check system health
   Next run: 2025-01-15 14:15:00 UTC
```

For agents with no schedules:
```
No schedules found for agent 'reporter'
```

**Error Handling:**
- Agent not found → `Error: LanguageAgent 'reporter' not found in namespace 'default'`

---

### 6. get_next_runs

Get the next N execution times for a cron expression.

**Parameters:**
- `schedule` (string, required) - Cron expression or natural language
- `count` (number, optional) - Number of upcoming runs to show (default: 5, max: 20)

**Returns:** List of next execution times

**Examples:**

Get next 5 runs:
```json
{
  "name": "get_next_runs",
  "arguments": {
    "schedule": "daily at 9am"
  }
}
```

Get next 10 runs:
```json
{
  "name": "get_next_runs",
  "arguments": {
    "schedule": "every Monday at 2pm",
    "count": 10
  }
}
```

Check interval timing:
```json
{
  "name": "get_next_runs",
  "arguments": {
    "schedule": "*/30 * * * *",
    "count": 8
  }
}
```

**Output Format:**
```
Next 5 runs for '0 9 * * *':
1. 2025-01-16 09:00:00 UTC
2. 2025-01-17 09:00:00 UTC
3. 2025-01-18 09:00:00 UTC
4. 2025-01-19 09:00:00 UTC
5. 2025-01-20 09:00:00 UTC
```

For intervals:
```
Next 8 runs for '*/30 * * * *':
1. 2025-01-15 14:30:00 UTC
2. 2025-01-15 15:00:00 UTC
3. 2025-01-15 15:30:00 UTC
4. 2025-01-15 16:00:00 UTC
5. 2025-01-15 16:30:00 UTC
6. 2025-01-15 17:00:00 UTC
7. 2025-01-15 17:30:00 UTC
8. 2025-01-15 18:00:00 UTC
```

**Error Handling:**
- Invalid schedule → `Error: Could not parse 'xyz' into a cron expression...`

---

### 7. schedule_once

Schedule a one-time task execution after a delay.

**Parameters:**
- `agent_name` (string, required) - Name of the LanguageAgent resource
- `namespace` (string, optional) - Kubernetes namespace (default: "default")
- `delay` (string, required) - Delay before execution (e.g., '5 minutes', '2 hours', '1 day')
- `task` (string, required) - Task description or prompt to execute
- `name` (string, optional) - Optional name for this scheduled task

**Returns:** Success message with execution time

**Supported Delay Formats:**

| Format | Examples | Description |
|--------|----------|-------------|
| Seconds | `30 seconds`, `45 sec`, `10 s` | 1-∞ seconds |
| Minutes | `5 minutes`, `15 min`, `30 m` | 1-∞ minutes |
| Hours | `2 hours`, `6 hr`, `12 h` | 1-∞ hours |
| Days | `1 day`, `3 days`, `7 d` | 1-∞ days |

**Examples:**

Schedule in 5 minutes:
```json
{
  "name": "schedule_once",
  "arguments": {
    "agent_name": "monitor",
    "delay": "5 minutes",
    "task": "Re-check system after previous alert"
  }
}
```

Schedule in 2 hours:
```json
{
  "name": "schedule_once",
  "arguments": {
    "agent_name": "deployer",
    "delay": "2 hours",
    "task": "Deploy updated application during maintenance window",
    "name": "maintenance-deploy"
  }
}
```

Schedule tomorrow:
```json
{
  "name": "schedule_once",
  "arguments": {
    "agent_name": "reporter",
    "delay": "1 day",
    "task": "Generate special monthly report"
  }
}
```

**Output Format:**
```
One-time schedule created successfully:
Agent: monitor
Execute at: 2025-01-15 14:35:00 UTC
Task: Re-check system after previous alert
```

**Error Handling:**
- Invalid delay → `Error: Could not parse delay '5 mins'. Use format like '5 minutes', '2 hours', '1 day'`
- Agent not found → `Error: LanguageAgent 'monitor' not found in namespace 'default'`

**Note:** The schedule is automatically removed after execution by the Language Operator controller (if `once: true` is set).

---

## Configuration

### RBAC Permissions

The Cron Tool requires read/write access to LanguageAgent CRDs:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: cron-tool
  namespace: default
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: cron-tool
rules:
- apiGroups: ["langop.io"]
  resources: ["languageagents"]
  verbs: ["get", "list", "update", "patch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: cron-tool
subjects:
- kind: ServiceAccount
  name: cron-tool
  namespace: default
roleRef:
  kind: ClusterRole
  name: cron-tool
  apiGroup: rbac.authorization.k8s.io
```

### Environment Variables

No environment variables required. The tool uses in-cluster Kubernetes configuration automatically.

---

## Deployment

### As a LanguageTool

```yaml
apiVersion: langop.io/v1alpha1
kind: LanguageTool
metadata:
  name: cron
spec:
  image: git.theryans.io/language-operator/cron-tool:latest
  deploymentMode: service
  port: 80
  type: mcp
  authRequired: true
  serviceAccount: cron-tool
```

### Agent Configuration

```yaml
apiVersion: langop.io/v1alpha1
kind: LanguageAgent
metadata:
  name: self-scheduler
spec:
  instructions: |
    You can manage your own schedule.
    Use cron tools to create, update, and delete schedules as needed.
  tools:
  - cron
  - workspace
  - email
```

### Pre-configured Schedules

You can also define schedules directly in the LanguageAgent spec:

```yaml
apiVersion: langop.io/v1alpha1
kind: LanguageAgent
metadata:
  name: reporter
spec:
  instructions: |
    Generate reports on schedule
  tools:
  - workspace
  - email
  schedules:
  - name: daily-report
    cron: "0 9 * * *"
    task: "Generate and email daily summary report"
  - name: weekly-backup
    cron: "0 0 * * 0"
    task: "Backup workspace to external storage"
```

---

## How Schedules Work

### Schedule Storage

Schedules are stored in the LanguageAgent CRD spec:

```yaml
apiVersion: langop.io/v1alpha1
kind: LanguageAgent
metadata:
  name: reporter
spec:
  instructions: "..."
  tools: [...]
  schedules:
  - name: "daily-report"
    cron: "0 9 * * *"
    task: "Generate and email daily summary report"
  - cron: "*/15 * * * *"
    task: "Check system health"
  - name: "one-time-task"
    cron: "30 14 15 01 *"
    task: "Execute maintenance task"
    once: true
```

### Schedule Execution

The Language Operator controller:

1. Watches LanguageAgent resources for schedule changes
2. Evaluates cron expressions against current time
3. Creates agent execution contexts when schedules trigger
4. Passes the `task` value as the agent's prompt
5. Removes schedules marked with `once: true` after execution

### Self-Modification

Agents with the cron tool can modify their own schedules:

```yaml
apiVersion: langop.io/v1alpha1
kind: LanguageAgent
metadata:
  name: adaptive-agent
spec:
  instructions: |
    Monitor your workload.
    If busy, reduce check frequency using update_schedule.
    If idle, increase frequency.
    Your current agent name is 'adaptive-agent'.
  tools:
  - cron
  - k8s
  schedules:
  - name: workload-check
    cron: "*/5 * * * *"
    task: "Check workload and adjust schedule as needed"
```

---

## Cron Expression Format

Standard 5-field cron format:

```
┌───────────── minute (0 - 59)
│ ┌───────────── hour (0 - 23)
│ │ ┌───────────── day of month (1 - 31)
│ │ │ ┌───────────── month (1 - 12)
│ │ │ │ ┌───────────── day of week (0 - 6) (Sunday = 0)
│ │ │ │ │
* * * * *
```

### Special Characters

| Character | Meaning | Example |
|-----------|---------|---------|
| `*` | Any value | `* * * * *` = every minute |
| `,` | List | `0 9,17 * * *` = 9am and 5pm |
| `-` | Range | `0 9 * * 1-5` = 9am weekdays |
| `/` | Step | `*/15 * * * *` = every 15 minutes |

### Common Examples

| Cron | Description |
|------|-------------|
| `0 * * * *` | Every hour |
| `0 0 * * *` | Daily at midnight |
| `0 9 * * *` | Daily at 9am |
| `0 9 * * 1` | Every Monday at 9am |
| `0 9 * * 1-5` | Weekdays at 9am |
| `*/15 * * * *` | Every 15 minutes |
| `0 */6 * * *` | Every 6 hours |
| `0 0 1 * *` | First day of month |
| `0 0 * * 0` | Every Sunday |

---

## MCP Protocol Compliance

### Initialization

```json
POST /mcp
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "initialize",
  "params": {
    "protocolVersion": "2024-11-05",
    "capabilities": {},
    "clientInfo": {"name": "agent", "version": "1.0"}
  }
}
```

Response:
```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "protocolVersion": "2024-11-05",
    "serverInfo": {
      "name": "cron-tool",
      "version": "1.0.0"
    },
    "capabilities": {
      "tools": {}
    }
  }
}
```

---

## Health Check

```bash
curl http://cron.default.svc.cluster.local/health
```

Response:
```json
{
  "status": "ok",
  "service": "cron-tool",
  "version": "1.0.0"
}
```

---

## Testing

### Manual Testing

```bash
# Parse natural language
curl -X POST http://localhost:8080/mcp \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc":"2.0",
    "id":1,
    "method":"tools/call",
    "params":{
      "name":"parse_cron",
      "arguments":{"expression":"daily at 9am"}
    }
  }'

# Create schedule
curl -X POST http://localhost:8080/mcp \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc":"2.0",
    "id":2,
    "method":"tools/call",
    "params":{
      "name":"create_schedule",
      "arguments":{
        "agent_name":"test-agent",
        "schedule":"every 5 minutes",
        "task":"Test task"
      }
    }
  }'

# List schedules
curl -X POST http://localhost:8080/mcp \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc":"2.0",
    "id":3,
    "method":"tools/call",
    "params":{
      "name":"list_schedules",
      "arguments":{"agent_name":"test-agent"}
    }
  }'
```

### Automated Tests

```bash
cd cron
bundle install
bundle exec rspec
```

---

## Common Patterns

### Self-Adjusting Schedule

```yaml
apiVersion: langop.io/v1alpha1
kind: LanguageAgent
metadata:
  name: adaptive
spec:
  instructions: |
    Monitor system load every 5 minutes.
    If load is high, reduce check frequency to every 15 minutes.
    If load is normal, increase to every 5 minutes.
    Use update_schedule to adjust the 'monitor' schedule.
  tools:
  - cron
  - k8s
  schedules:
  - name: monitor
    cron: "*/5 * * * *"
    task: "Check system load and adjust schedule"
```

### Retry with Backoff

```yaml
apiVersion: langop.io/v1alpha1
kind: LanguageAgent
metadata:
  name: retry-agent
spec:
  instructions: |
    Attempt task.
    If failed, use schedule_once to retry:
    - First retry: 1 minute
    - Second retry: 5 minutes
    - Third retry: 15 minutes
    - Final: email admin
  tools:
  - cron
  - email
```

### Business Hours Only

```yaml
apiVersion: langop.io/v1alpha1
kind: LanguageAgent
metadata:
  name: business-hours
spec:
  instructions: |
    Process requests during business hours only
  tools:
  - workspace
  - email
  schedules:
  - name: morning-start
    cron: "0 9 * * 1-5"
    task: "Start processing daily requests"
  - name: evening-stop
    cron: "0 17 * * 1-5"
    task: "Stop processing and generate summary"
```

### Scheduled Maintenance

```yaml
apiVersion: langop.io/v1alpha1
kind: LanguageAgent
metadata:
  name: maintenance
spec:
  instructions: |
    Perform maintenance tasks on schedule
  tools:
  - cron
  - k8s
  - workspace
  schedules:
  - name: daily-cleanup
    cron: "0 2 * * *"
    task: "Clean up old pods and temporary resources"
  - name: weekly-backup
    cron: "0 0 * * 0"
    task: "Backup critical data to workspace"
  - name: monthly-report
    cron: "0 9 1 * *"
    task: "Generate monthly maintenance report"
```

---

## Troubleshooting

### Common Issues

**"Error: LanguageAgent 'X' not found"**
- Cause: Agent doesn't exist or wrong namespace
- Solution:
  - Verify agent exists: `kubectl get languageagents`
  - Check namespace is correct
  - Ensure agent is in the same namespace as specified

**"Error: Could not parse 'X' into a cron expression"**
- Cause: Invalid natural language or cron syntax
- Solution:
  - Use `parse_cron` to test expression first
  - Check supported natural language patterns
  - Verify cron syntax: `minute hour day month weekday`
  - Use standard patterns: 'daily at 9am', 'every Monday'

**"Error: Must specify either schedule_index or schedule_name"**
- Cause: Updating/deleting without identifier
- Solution:
  - Use `list_schedules` to find index or name
  - Provide either `schedule_index` (0-based) or `schedule_name`

**"Error: Schedule not found"**
- Cause: Invalid index or name
- Solution:
  - Use `list_schedules` to see available schedules
  - Check index is within range (0-based)
  - Verify schedule name matches exactly (case-sensitive)

**Schedule not executing**
- Cause: Language Operator controller not watching
- Solution:
  - Check Language Operator is running: `kubectl get pods -n language-operator-system`
  - Verify controller logs: `kubectl logs -n language-operator-system deployment/language-operator-controller`
  - Check agent has valid schedules: `kubectl get languageagent X -o yaml`

**Permission denied**
- Cause: ServiceAccount lacks RBAC permissions
- Solution:
  - Verify ServiceAccount: `kubectl get sa cron-tool`
  - Check ClusterRole exists: `kubectl get clusterrole cron-tool`
  - Verify binding: `kubectl get clusterrolebinding cron-tool`
  - Test permissions: `kubectl auth can-i update languageagents --as system:serviceaccount:default:cron-tool`

---

## Performance Considerations

### Schedule Evaluation

- Language Operator evaluates schedules every minute
- Cron expressions are parsed once and cached
- Schedule modifications are immediate (next evaluation cycle)

### CRD Update Frequency

- Each schedule create/update/delete modifies the LanguageAgent CRD
- Frequent modifications may trigger reconciliation loops
- Recommendation: Batch schedule changes when possible

### Natural Language Parsing

- Natural language is converted to cron expressions once
- Parsing is fast (~1ms per expression)
- Cron expressions are stored, not natural language

### One-Time Schedules

- Marked with `once: true` flag
- Automatically removed by controller after execution
- Use for retry logic and delayed tasks

---

## Best Practices

1. **Use Named Schedules**: Assign names for easy identification and updates
2. **Test Expressions**: Use `parse_cron` to validate before creating
3. **Check Next Runs**: Use `get_next_runs` to verify timing
4. **List Before Update**: Use `list_schedules` to find correct index
5. **Self-Awareness**: Agents should know their own name for self-modification
6. **Document Tasks**: Use clear, descriptive task descriptions
7. **Avoid Conflicts**: Don't schedule overlapping long-running tasks
8. **Use schedule_once**: For retry logic and delayed operations
9. **Monitor Execution**: Check agent logs for schedule execution
10. **Clean Up**: Delete unused schedules to reduce clutter

---

## Advanced Usage

### Dynamic Schedule Adjustment

An agent can adjust its own schedule based on external factors:

```yaml
instructions: |
  Every hour, check cluster resource usage.
  If CPU > 80%, reduce check frequency to every 2 hours.
  If CPU < 40%, increase to every 30 minutes.
  Update your own 'resource-check' schedule accordingly.
```

### Multi-Schedule Coordination

```yaml
schedules:
- name: data-collection
  cron: "*/5 * * * *"
  task: "Collect metrics data"
- name: data-processing
  cron: "10 * * * *"
  task: "Process collected metrics from last hour"
- name: data-cleanup
  cron: "0 0 * * *"
  task: "Archive and clean up old metrics"
```

### Conditional Scheduling

```yaml
instructions: |
  When task X completes successfully, schedule task Y in 1 hour.
  If task X fails, schedule retry in 5 minutes.
  After 3 retries, email admin and remove schedule.
```

---

## Version

**Current Version:** 1.0.0

**MCP Protocol:** 2024-11-05

**Language Operator Compatibility:** v0.2.0+

**Dependencies:**
- rufus-scheduler: ~> 3.9
- chronic: ~> 0.10
- k8s-ruby: ~> 0.11

---

## License

MIT License - see [LICENSE](../LICENSE)
