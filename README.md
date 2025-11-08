# Language Operator Tools

**Everything your autonomous agents need. Nothing they don't.**

This is the official tool registry for [Language Operator](https://git.theryans.io/language-operator/language-operator)—a curated collection of MCP-compatible tools that give your agents superpowers.

**The philosophy:** Five essential tools. Zero bloat. Maximum capability.

---

## Why These Tools Are All You Need

When you describe a task in natural language, Language Operator synthesizes an autonomous agent. That agent needs tools to interact with the world. We built exactly what's needed—no more, no less.

**Web Tool:** Your agent can search the internet and fetch web pages.
**Email Tool:** Your agent can send and receive emails.
**Workspace Tool:** Your agent can remember things across executions.
**Kubernetes Tool:** Your agent can manage itself and other workloads.
**MCP Bridge Tool:** Your agent can access the entire MCP ecosystem.

That's it. **Everything else is just a specialized MCP server accessible via the bridge.**

With these five tools, agents can:
- Monitor your systems and send alerts
- Review documents and email you summaries
- Coordinate with external services via MCP
- Self-heal by managing their own Kubernetes resources
- Build knowledge over time with persistent storage

**Simplicity is a feature. These tools are battle-tested, secure by default, and designed to compose.**

---

## The Core Five

### 🌐 Web Tool
**Search the web. Fetch pages. Stay informed.**

Your agent can use DuckDuckGo to search the internet and retrieve web content.

```yaml
apiVersion: langop.io/v1alpha1
kind: LanguageTool
metadata:
  name: web
spec:
  image: git.theryans.io/language-operator/web-tool:latest
```

**What it does:**
- Web search via DuckDuckGo
- Fetch and parse web pages
- Monitor URLs for changes

**Perfect for:**
- "Check Hacker News daily and summarize top posts"
- "Monitor my competitor's blog and alert me to new posts"
- "Search for the latest security advisories every hour"

---

### 📧 Email Tool
**Send notifications. Receive triggers. Stay connected.**

Your agent can send emails via SMTP and read emails via IMAP.

```yaml
apiVersion: langop.io/v1alpha1
kind: LanguageTool
metadata:
  name: email
spec:
  image: git.theryans.io/language-operator/email-tool:latest
  authRequired: true
```

**What it does:**
- Send email via SMTP
- Read email via IMAP
- Filter and categorize messages

**Perfect for:**
- "Email me a summary of errors from the logs every morning"
- "When someone emails support@, create a ticket and send an auto-reply"
- "Scan my inbox for urgent client emails and alert me"

---

### 📁 Workspace Tool
**Persistent memory. Stateful workflows. Knowledge over time.**

Your agent gets a shared workspace to read and write files across executions.

```yaml
apiVersion: langop.io/v1alpha1
kind: LanguageTool
metadata:
  name: workspace
spec:
  image: git.theryans.io/language-operator/workspace-tool:latest
  volumes:
  - name: workspace
    mountPath: /workspace
    persistentVolumeClaim:
      claimName: agent-workspace
```

**What it does:**
- Read and write files to persistent storage
- Remember state between executions
- Share data between agents and tools

**Perfect for:**
- "Track which spreadsheet cells I've already reviewed"
- "Build a knowledge base of past incident responses"
- "Remember the last time I sent a summary email"

---

### ☸️ Kubernetes Tool
**Self-managing agents. Infrastructure automation. Total control.**

Your agent can manage Kubernetes resources—including itself.

```yaml
apiVersion: langop.io/v1alpha1
kind: LanguageTool
metadata:
  name: k8s
spec:
  image: git.theryans.io/language-operator/k8s-tool:latest
  rbac:
    clusterRole:
      rules:
      - apiGroups: ["*"]
        resources: ["*"]
        verbs: ["get", "list", "watch"]
```

**What it does:**
- Read and modify Kubernetes resources
- Query pod logs and status
- Self-heal by restarting or scaling itself

**Perfect for:**
- "If error rate spikes, scale up the API deployment"
- "Monitor my pods and alert me if any are crashing"
- "Rotate secrets every 30 days automatically"

---

### 🔌 MCP Bridge Tool
**Access the entire MCP ecosystem. Infinite extensibility.**

Your agent can discover and call any MCP server in your cluster.

```yaml
apiVersion: langop.io/v1alpha1
kind: LanguageTool
metadata:
  name: mcp
spec:
  image: git.theryans.io/language-operator/mcp-tool:latest
```

**What it does:**
- Discover available MCP servers
- Call tools from any MCP server
- Proxy requests to external MCP servers

**Perfect for:**
- Connecting to Google Sheets, Slack, GitHub, or any MCP server
- Building custom tools without modifying Language Operator
- Accessing proprietary internal APIs via MCP

**This is the escape hatch.** Need something specialized? Deploy an MCP server and the bridge connects your agent to it automatically.

---

## How Tools Work

### 1. Define the Tool
```yaml
apiVersion: langop.io/v1alpha1
kind: LanguageTool
metadata:
  name: web
spec:
  image: git.theryans.io/language-operator/web-tool:latest
  deploymentMode: service
  port: 80
```

### 2. Reference in Your Agent
```yaml
apiVersion: langop.io/v1alpha1
kind: LanguageAgent
metadata:
  name: news-summarizer
spec:
  instructions: |
    Search Hacker News daily and email me the top 5 posts
  tools:
  - web
  - email
```

### 3. The Agent Calls the Tool
```ruby
# Synthesized code (auto-generated)
step :search_news,
  tool: "web",
  params: { query: "site:news.ycombinator.com" }

step :send_summary,
  tool: "email",
  params: { to: "user@example.com", subject: "Daily HN Summary" }
```

**Tools are MCP servers. Agents call them via standardized APIs. No custom integrations needed.**

---

## Network Isolation by Default

Every tool is network-isolated. They can only talk to what you explicitly allow.

```yaml
apiVersion: langop.io/v1alpha1
kind: LanguageTool
metadata:
  name: web
spec:
  egress:
  - description: Allow HTTPS to DuckDuckGo
    dns:
    - "*.duckduckgo.com"
    ports:
    - port: 443
      protocol: TCP
```

**Zero-trust by default. No tool has internet access unless you grant it.**

---

## Why MCP?

**Model Context Protocol (MCP)** is an open standard for tool integration. Instead of building custom connectors, we use MCP and get:

- **Standardized APIs:** Every tool looks the same to agents
- **Ecosystem access:** 100+ existing MCP servers work out of the box
- **Composability:** Tools combine without custom glue code
- **Future-proof:** As MCP grows, so does Language Operator

**The MCP Bridge Tool means you never need to ask us to add support for X. Just deploy an MCP server.**

---

## Tool Registry

All tools are published in [index.yaml](./index.yaml) with metadata:

```yaml
tools:
  web:
    name: web
    displayName: Web Tool
    description: Search the web and fetch web pages
    image: git.theryans.io/language-operator/web-tool:latest
    type: mcp
    egress:
    - description: Allow HTTPS to DuckDuckGo
      dns:
      - "*.duckduckgo.com"
```

The Language Operator reads this registry and provisions tools automatically.

---

## Building Custom Tools

Want to add your own tool? It's just an MCP server.

### 1. Implement the MCP Protocol
Your tool must support:
- `tools/list` - Return available tools
- `tools/call` - Execute a tool

### 2. Package as a Container
```dockerfile
FROM ruby:3.3
COPY . /app
CMD ["ruby", "server.rb"]
```

### 3. Deploy It
```yaml
apiVersion: langop.io/v1alpha1
kind: LanguageTool
metadata:
  name: my-custom-tool
spec:
  image: myregistry.io/my-tool:latest
  deploymentMode: service
  port: 80
```

**That's it.** Your agent can now call your custom tool via the MCP bridge.

See [web/](./web/), [email/](./email/), or [workspace/](./workspace/) for reference implementations.

---

## Security Model

**1. Network Isolation:** Tools can't talk to the internet unless explicitly allowed via `egress` rules.

**2. RBAC:** Kubernetes tools need explicit permissions via `clusterRole`.

**3. Authentication:** Tools requiring credentials (email, APIs) use Kubernetes secrets.

**4. Least Privilege:** Each tool gets only the permissions it needs—nothing more.

**Example:**
```yaml
apiVersion: langop.io/v1alpha1
kind: LanguageTool
metadata:
  name: email
spec:
  authRequired: true
  egress:
  - description: Allow SMTP
    dns: ["smtp.gmail.com"]
    ports:
    - port: 587
      protocol: TCP
```

**No wildcards. No overly broad permissions. No surprises.**

---

## Tool Lifecycle

### Deployment Modes

**Service:** Long-running MCP server (default for most tools)
```yaml
deploymentMode: service
```

**Sidecar:** Runs alongside each agent pod (for filesystem access)
```yaml
deploymentMode: sidecar
```

**Job:** One-shot execution (rare, for batch operations)
```yaml
deploymentMode: job
```

### Health Checks

Tools expose `/health` for liveness probes:
```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 80
```

### Updates

Tools are versioned. Update the image tag and Language Operator rolls out the new version:
```yaml
spec:
  image: git.theryans.io/language-operator/web-tool:v1.2.0
```

---

## Philosophy

**Simplicity over features.**
Five core tools that compose infinitely via MCP.

**Security by default.**
Network isolation, RBAC, least privilege—always.

**MCP-native.**
One protocol to rule them all. No custom integrations.

**Agent-first design.**
Tools exist to serve agents, not the other way around.

---

## Get Started

### Install Language Operator
```bash
helm install language-operator oci://git.theryans.io/helm/language-operator
```

### Create an Agent
```bash
aictl agent create "search Hacker News daily and email me the top posts"
```

### Your Agent Has Tools
```bash
aictl agent inspect news-summarizer

Tools:
  - web (connected)
  - email (connected)
```

**That's it. Your agent is autonomous and tool-enabled.**

---

## Contributing

**Want to add a tool?**

1. Implement MCP protocol
2. Add to `index.yaml`
3. Submit PR

See [CONTRIBUTING.md](./CONTRIBUTING.md) for details.

**Want to improve existing tools?**

Browse the source in [web/](./web/), [email/](./email/), [workspace/](./workspace/), [k8s/](./k8s/), or [mcp/](./mcp/).

---

## License

MIT License - see [LICENSE](./LICENSE)

---

## The Big Picture

Language Operator turns natural language into autonomous agents.

**These tools are how those agents interact with the world.**

No bloat. No complexity. Just five essential tools and the MCP ecosystem.

**Everything your agents need. Nothing they don't.**

```bash
aictl agent create "..."
```

**Welcome to agent-native infrastructure.**