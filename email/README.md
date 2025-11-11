# Email Tool

**Send and receive emails via SMTP/IMAP**

The Email Tool provides email capabilities for Language Operator agents, allowing them to send notifications, alerts, and reports via SMTP.

## Overview

- **Type:** MCP Server
- **Deployment Mode:** Service
- **Port:** 80
- **Protocols:** SMTP (sending)
- **Authentication:** Required via environment variables
- **Security:** TLS encryption enabled by default

## Use Cases

### Notifications & Alerts
```yaml
apiVersion: langop.io/v1alpha1
kind: LanguageAgent
metadata:
  name: alert-manager
spec:
  instructions: |
    Monitor system health and email alerts when issues are detected
  tools:
  - k8s
  - email
```

**Perfect for:**
- System health alerts
- Error notifications
- Deployment notifications
- Threshold breach alerts

### Automated Reporting
```yaml
apiVersion: langop.io/v1alpha1
kind: LanguageAgent
metadata:
  name: daily-reporter
spec:
  instructions: |
    Generate and email daily summary reports at 9am
  tools:
  - workspace
  - web
  - email
```

**Perfect for:**
- Daily/weekly summaries
- Performance reports
- Usage statistics
- Compliance reports

### Workflow Notifications
```yaml
apiVersion: langop.io/v1alpha1
kind: LanguageAgent
metadata:
  name: workflow-notifier
spec:
  instructions: |
    Send status updates as tasks complete
  tools:
  - email
  - workspace
```

**Perfect for:**
- Task completion notifications
- Approval requests
- Status updates
- Team coordination

---

## Tools

The Email Tool exposes 3 MCP tools for email operations:

### 1. send_email

Send an email via SMTP.

**Parameters:**
- `to` (string, required) - Recipient email address (comma-separated for multiple recipients)
- `subject` (string, required) - Email subject line
- `body` (string, required) - Email body content (plain text or HTML)
- `from` (string, optional) - Sender email address (defaults to SMTP_FROM env variable)
- `cc` (string, optional) - CC email addresses (comma-separated)
- `bcc` (string, optional) - BCC email addresses (comma-separated)
- `html` (boolean, optional) - Send as HTML email (default: false)

**Returns:** Success message with recipient list

**Examples:**

Simple email:
```json
{
  "name": "send_email",
  "arguments": {
    "to": "user@example.com",
    "subject": "Task Completed",
    "body": "The deployment task completed successfully at 14:30."
  }
}
```

Multiple recipients:
```json
{
  "name": "send_email",
  "arguments": {
    "to": "alice@example.com, bob@example.com",
    "subject": "Team Update",
    "body": "Sprint planning meeting scheduled for Friday at 2pm."
  }
}
```

With CC and BCC:
```json
{
  "name": "send_email",
  "arguments": {
    "to": "manager@example.com",
    "cc": "team@example.com",
    "bcc": "archive@example.com",
    "subject": "Monthly Report",
    "body": "Please find the monthly report attached..."
  }
}
```

HTML email:
```json
{
  "name": "send_email",
  "arguments": {
    "to": "stakeholders@example.com",
    "subject": "System Status Report",
    "body": "<h1>System Status</h1><p><strong>All systems operational</strong></p><ul><li>API: ✓</li><li>Database: ✓</li><li>Cache: ✓</li></ul>",
    "html": true
  }
}
```

Custom sender:
```json
{
  "name": "send_email",
  "arguments": {
    "to": "recipient@example.com",
    "from": "noreply@example.com",
    "subject": "Automated Alert",
    "body": "This is an automated message from the monitoring system."
  }
}
```

**Output Format:**
```
Email sent successfully to user@example.com
```

For multiple recipients:
```
Email sent successfully to alice@example.com, bob@example.com
```

**Error Handling:**
- Missing sender → `Error: No sender address specified. Set SMTP_FROM or provide 'from' parameter.`
- Missing SMTP config → `Error: SMTP configuration missing. Please set SMTP_HOST, SMTP_USER, and SMTP_PASSWORD environment variables.`
- Send failure → `Error sending email: <reason>`

---

### 2. test_smtp

Test SMTP connection and configuration.

**Parameters:** None

**Returns:** Configuration summary and connection test result

**Examples:**

Test connection:
```json
{
  "name": "test_smtp",
  "arguments": {}
}
```

**Output Format (Success):**
```
SMTP Configuration Test: SUCCESS

Host: smtp.gmail.com
Port: 587
User: notifications@example.com
From: notifications@example.com
TLS: true

Connection to SMTP server successful!
```

**Output Format (Failure):**
```
SMTP Configuration Test: FAILED

Host: smtp.gmail.com
Port: 587
User: notifications@example.com

Error: Authentication failed - invalid credentials
```

**Error Handling:**
- Missing configuration → `Error: Missing SMTP configuration: SMTP_HOST, SMTP_USER, SMTP_PASSWORD`
- Connection failed → Shows error message with details

---

### 3. email_config

Display current email configuration (without sensitive data).

**Parameters:** None

**Returns:** Configuration summary with password masked

**Examples:**

View configuration:
```json
{
  "name": "email_config",
  "arguments": {}
}
```

**Output Format:**
```
Email Configuration:

SMTP_HOST: smtp.gmail.com
SMTP_PORT: 587
SMTP_USER: notifications@example.com
SMTP_FROM: notifications@example.com
SMTP_TLS: true
SMTP_PASSWORD: Yes (hidden)

Note: Set these via environment variables when running the container.
```

---

## Configuration

### Environment Variables

All SMTP configuration is provided via environment variables:

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `SMTP_HOST` | Yes | - | SMTP server hostname (e.g., smtp.gmail.com) |
| `SMTP_PORT` | No | 587 | SMTP port (587 for TLS, 465 for SSL) |
| `SMTP_USER` | Yes | - | SMTP username (often your email address) |
| `SMTP_PASSWORD` | Yes | - | SMTP password or app-specific password |
| `SMTP_FROM` | No | SMTP_USER | Default sender email address |
| `SMTP_TLS` | No | true | Use TLS encryption (recommended) |

### Common SMTP Providers

#### Gmail
```yaml
env:
- name: SMTP_HOST
  value: smtp.gmail.com
- name: SMTP_PORT
  value: "587"
- name: SMTP_USER
  value: your-email@gmail.com
- name: SMTP_PASSWORD
  valueFrom:
    secretKeyRef:
      name: email-credentials
      key: password
- name: SMTP_TLS
  value: "true"
```

**Note:** Gmail requires an [app-specific password](https://myaccount.google.com/apppasswords) if 2FA is enabled.

#### Outlook/Office 365
```yaml
env:
- name: SMTP_HOST
  value: smtp.office365.com
- name: SMTP_PORT
  value: "587"
- name: SMTP_USER
  value: your-email@outlook.com
- name: SMTP_PASSWORD
  valueFrom:
    secretKeyRef:
      name: email-credentials
      key: password
```

#### SendGrid
```yaml
env:
- name: SMTP_HOST
  value: smtp.sendgrid.net
- name: SMTP_PORT
  value: "587"
- name: SMTP_USER
  value: apikey
- name: SMTP_PASSWORD
  valueFrom:
    secretKeyRef:
      name: sendgrid-credentials
      key: api-key
```

#### Mailgun
```yaml
env:
- name: SMTP_HOST
  value: smtp.mailgun.org
- name: SMTP_PORT
  value: "587"
- name: SMTP_USER
  value: postmaster@your-domain.mailgun.org
- name: SMTP_PASSWORD
  valueFrom:
    secretKeyRef:
      name: mailgun-credentials
      key: smtp-password
```

---

## Network Security

### Egress Control

The Email Tool requires network egress to SMTP servers:

```yaml
apiVersion: langop.io/v1alpha1
kind: LanguageTool
metadata:
  name: email
spec:
  image: ghcr.io/language-operator/email-tool:latest
  authRequired: true
  egress:
  - description: Allow SMTP/IMAP connections
    dns:
    - "*"
    ports:
    - port: 587
      protocol: TCP
    - port: 465
      protocol: TCP
    - port: 993
      protocol: TCP
```

### Restricted Access

Limit to specific SMTP server:

```yaml
egress:
- description: Allow Gmail SMTP
  dns:
  - "smtp.gmail.com"
  ports:
  - port: 587
    protocol: TCP
```

---

## Deployment

### As a LanguageTool

```yaml
apiVersion: langop.io/v1alpha1
kind: LanguageTool
metadata:
  name: email
spec:
  image: ghcr.io/language-operator/email-tool:latest
  deploymentMode: service
  port: 80
  type: mcp
  authRequired: true
  env:
  - name: SMTP_HOST
    value: smtp.gmail.com
  - name: SMTP_PORT
    value: "587"
  - name: SMTP_USER
    valueFrom:
      secretKeyRef:
        name: email-smtp
        key: username
  - name: SMTP_PASSWORD
    valueFrom:
      secretKeyRef:
        name: email-smtp
        key: password
  - name: SMTP_FROM
    value: notifications@example.com
  - name: SMTP_TLS
    value: "true"
  egress:
  - description: Allow SMTP
    dns:
    - "smtp.gmail.com"
    ports:
    - port: 587
      protocol: TCP
```

### Create SMTP Secret

```bash
kubectl create secret generic email-smtp \
  --from-literal=username=your-email@gmail.com \
  --from-literal=password=your-app-password
```

Or via YAML:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: email-smtp
type: Opaque
stringData:
  username: your-email@gmail.com
  password: your-app-password
```

### Agent Configuration

```yaml
apiVersion: langop.io/v1alpha1
kind: LanguageAgent
metadata:
  name: alert-notifier
spec:
  instructions: |
    Monitor logs and send email alerts for errors
  tools:
  - email
  - workspace
```

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
      "name": "email-tool",
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
curl http://email.default.svc.cluster.local/health
```

Response:
```json
{
  "status": "ok",
  "service": "email-tool",
  "version": "1.0.0"
}
```

---

## Testing

### Manual Testing

```bash
# Test SMTP configuration
curl -X POST http://localhost:8080/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"test_smtp","arguments":{}}}'

# View configuration
curl -X POST http://localhost:8080/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"email_config","arguments":{}}}'

# Send test email
curl -X POST http://localhost:8080/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"send_email","arguments":{"to":"test@example.com","subject":"Test","body":"This is a test"}}}'
```

### Automated Tests

```bash
cd email
bundle install
bundle exec rspec
```

---

## Security Best Practices

### 1. Never Commit Credentials

Always use Kubernetes secrets for SMTP credentials:

```yaml
# ❌ Bad - credentials in plain text
env:
- name: SMTP_PASSWORD
  value: "my-password"

# ✅ Good - credentials from secret
env:
- name: SMTP_PASSWORD
  valueFrom:
    secretKeyRef:
      name: email-smtp
      key: password
```

### 2. Use App-Specific Passwords

For providers like Gmail with 2FA enabled, use app-specific passwords:
- Gmail: https://myaccount.google.com/apppasswords
- Outlook: https://account.microsoft.com/security

### 3. Enable TLS

Always use TLS encryption (enabled by default):

```yaml
env:
- name: SMTP_TLS
  value: "true"
```

### 4. Restrict Network Access

Limit egress to only required SMTP servers:

```yaml
egress:
- description: Allow specific SMTP server only
  dns:
  - "smtp.gmail.com"
  ports:
  - port: 587
    protocol: TCP
```

### 5. Rate Limiting

Be aware of SMTP provider rate limits:
- Gmail: 500 emails/day (free), 2000/day (Google Workspace)
- SendGrid: Varies by plan
- Mailgun: Varies by plan

Implement delays in agents if sending many emails.

---

## Troubleshooting

### Common Issues

**"Error: SMTP configuration missing"**
- Cause: Required environment variables not set
- Solution: Set `SMTP_HOST`, `SMTP_USER`, and `SMTP_PASSWORD`

**"Error: No sender address specified"**
- Cause: No `SMTP_FROM` and no `from` parameter
- Solution: Set `SMTP_FROM` env var or provide `from` in request

**"Authentication failed"**
- Cause: Invalid credentials or 2FA issues
- Solution:
  - Verify credentials are correct
  - Use app-specific password for Gmail/Outlook
  - Check if account requires special configuration

**"Connection timeout"**
- Cause: Network/firewall blocking SMTP
- Solution:
  - Verify `SMTP_HOST` and `SMTP_PORT` are correct
  - Check firewall/network policies
  - Verify egress rules allow SMTP traffic

**Emails not received**
- Cause: Various delivery issues
- Solution:
  - Check recipient spam/junk folder
  - Verify recipient address is correct
  - Check SMTP provider logs
  - Test with `test_smtp` tool first

**"SSL/TLS error"**
- Cause: Certificate or protocol mismatch
- Solution:
  - Verify correct port (587 for TLS, 465 for SSL)
  - Check `SMTP_TLS` setting matches port
  - Update SMTP server hostname if changed

---

## Performance Considerations

### Email Delivery

- Emails are sent synchronously (blocks until complete)
- Typical send time: 1-5 seconds
- For bulk emails, implement delays to avoid rate limits

### Rate Limits

Different providers have different limits:

| Provider | Rate Limit | Notes |
|----------|------------|-------|
| Gmail (Free) | 500/day | Per account |
| Google Workspace | 2000/day | Per account |
| SendGrid Free | 100/day | Increase with paid plans |
| Mailgun Free | 1000/month | Increase with paid plans |
| Outlook | 300/day | Per account |

### Optimization

For high-volume email:
1. Use transactional email services (SendGrid, Mailgun)
2. Batch recipients in single email when appropriate
3. Implement exponential backoff for retries
4. Monitor provider logs for bounce/complaint rates

---

## Best Practices

1. **Test configuration first**: Always run `test_smtp` before deploying
2. **Use secrets**: Never hardcode credentials
3. **Set sender address**: Configure `SMTP_FROM` for consistency
4. **HTML with care**: Test HTML emails across clients
5. **Monitor delivery**: Check provider dashboards regularly
6. **Handle errors**: Always check email send results
7. **Respect limits**: Don't exceed provider rate limits
8. **Use templates**: Store email templates in workspace for reuse

---

## Version

**Current Version:** 1.0.0

**MCP Protocol:** 2024-11-05

**Language Operator Compatibility:** v0.2.0+

---

## License

MIT License - see [LICENSE](../LICENSE)
