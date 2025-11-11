# Kubernetes Tool

**Full Kubernetes API access for autonomous agents**

The Kubernetes Tool provides comprehensive Kubernetes cluster management capabilities for Language Operator agents, enabling self-managing infrastructure, autonomous deployments, and intelligent orchestration.

## Overview

- **Type:** MCP Server
- **Deployment Mode:** Service
- **Port:** 80
- **API Access:** Full Kubernetes API via k8s-ruby client
- **Authentication:** In-cluster ServiceAccount with RBAC
- **Scope:** Namespace-scoped or cluster-wide based on permissions

## Use Cases

### Self-Managing Agents
```yaml
apiVersion: langop.io/v1alpha1
kind: LanguageAgent
metadata:
  name: self-manager
spec:
  instructions: |
    Monitor your own health and restart if needed
  tools:
  - k8s
```

**Perfect for:**
- Self-healing agents
- Dynamic resource allocation
- Auto-scaling based on workload
- Self-updating deployments

### Infrastructure Automation
```yaml
apiVersion: langop.io/v1alpha1
kind: LanguageAgent
metadata:
  name: infra-orchestrator
spec:
  instructions: |
    Deploy and manage microservices based on requirements
  tools:
  - k8s
  - workspace
```

**Perfect for:**
- Automated deployments
- Service mesh management
- Resource provisioning
- Configuration management

### Monitoring & Response
```yaml
apiVersion: langop.io/v1alpha1
kind: LanguageAgent
metadata:
  name: cluster-monitor
spec:
  instructions: |
    Watch cluster health and take corrective action
  tools:
  - k8s
  - email
```

**Perfect for:**
- Incident response
- Log analysis
- Performance optimization
- Capacity planning

### Multi-Cluster Orchestration
```yaml
apiVersion: langop.io/v1alpha1
kind: LanguageAgent
metadata:
  name: multi-cluster-manager
spec:
  instructions: |
    Coordinate workloads across multiple clusters
  tools:
  - k8s
  - web
```

**Perfect for:**
- Cross-cluster deployments
- Disaster recovery
- Load balancing
- Geographic distribution

---

## Tools

The Kubernetes Tool exposes 6 MCP tools for cluster management:

### 1. k8s_get

Get a specific Kubernetes resource by name.

**Parameters:**
- `resource` (string, required) - Resource type (e.g., 'pod', 'deployment', 'service')
- `name` (string, required) - Resource name
- `namespace` (string, optional) - Namespace (omit for cluster-scoped resources or current namespace)
- `output` (string, optional) - Output format: 'summary' or 'yaml' (default: summary)

**Returns:** Resource details in requested format

**Examples:**

Get a pod summary:
```json
{
  "name": "k8s_get",
  "arguments": {
    "resource": "pod",
    "name": "nginx-7f456874f4-x9k2m",
    "namespace": "default"
  }
}
```

Get deployment as YAML:
```json
{
  "name": "k8s_get",
  "arguments": {
    "resource": "deployment",
    "name": "api-server",
    "namespace": "production",
    "output": "yaml"
  }
}
```

Get cluster-scoped resource:
```json
{
  "name": "k8s_get",
  "arguments": {
    "resource": "node",
    "name": "worker-node-1"
  }
}
```

**Output Format (summary):**
```
Kind: Pod
Name: nginx-7f456874f4-x9k2m
Namespace: default
Created: 2025-01-15T10:30:00Z
Labels: {app: nginx, version: v1.0}
Spec keys: containers, volumes, restartPolicy
Status keys: phase, conditions, podIP
```

**Output Format (yaml):**
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-7f456874f4-x9k2m
  namespace: default
  labels:
    app: nginx
spec:
  containers:
  - name: nginx
    image: nginx:1.21
...
```

**Error Handling:**
- Resource not found → `Error: Resource not found - pod/nginx-7f456874f4-x9k2m`
- Access denied → `Error: Access denied - check RBAC permissions`
- Invalid resource type → `Error: Unknown resource type 'podz'`

---

### 2. k8s_list

List Kubernetes resources with optional label selector.

**Parameters:**
- `resource` (string, required) - Resource type (e.g., 'pods', 'deployments', 'services')
- `namespace` (string, optional) - Namespace (omit for all namespaces or cluster-scoped resources)
- `selector` (string, optional) - Label selector (e.g., 'app=nginx,env=prod')
- `limit` (number, optional) - Maximum number of resources to return (default: 50)

**Returns:** List of matching resources

**Examples:**

List all pods in namespace:
```json
{
  "name": "k8s_list",
  "arguments": {
    "resource": "pods",
    "namespace": "default"
  }
}
```

List with label selector:
```json
{
  "name": "k8s_list",
  "arguments": {
    "resource": "deployments",
    "namespace": "production",
    "selector": "app=api,version=v2"
  }
}
```

List across all namespaces:
```json
{
  "name": "k8s_list",
  "arguments": {
    "resource": "pods",
    "selector": "tier=frontend"
  }
}
```

List cluster-scoped resources:
```json
{
  "name": "k8s_list",
  "arguments": {
    "resource": "nodes",
    "limit": 10
  }
}
```

**Output Format:**
```
pods in namespace 'default':

nginx-7f456874f4-x9k2m (namespace: default, age: 5d)
redis-6d8f9c7b5-p4k8n (namespace: default, age: 3d)
postgres-5c7d8e6f4-q2m7k (namespace: default, age: 12d)
```

With selector:
```
deployments in namespace 'production' with selector 'app=api,version=v2':

api-server-v2 (namespace: production, age: 7d)
api-worker-v2 (namespace: production, age: 7d)
```

**Error Handling:**
- Access denied → `Error: Access denied - check RBAC permissions`
- Invalid selector → `Error: Invalid label selector syntax`

---

### 3. k8s_apply

Create or update a Kubernetes resource from YAML.

**Parameters:**
- `yaml` (string, required) - Resource YAML manifest
- `namespace` (string, optional) - Override namespace in manifest (optional)

**Returns:** Success message indicating whether resource was created or updated

**Examples:**

Create a deployment:
```json
{
  "name": "k8s_apply",
  "arguments": {
    "yaml": "apiVersion: apps/v1\nkind: Deployment\nmetadata:\n  name: nginx\n  namespace: default\nspec:\n  replicas: 3\n  selector:\n    matchLabels:\n      app: nginx\n  template:\n    metadata:\n      labels:\n        app: nginx\n    spec:\n      containers:\n      - name: nginx\n        image: nginx:1.21\n        ports:\n        - containerPort: 80"
  }
}
```

Update existing resource:
```json
{
  "name": "k8s_apply",
  "arguments": {
    "yaml": "apiVersion: v1\nkind: Service\nmetadata:\n  name: nginx\nspec:\n  selector:\n    app: nginx\n  ports:\n  - port: 80\n    targetPort: 80\n  type: LoadBalancer",
    "namespace": "production"
  }
}
```

Create ConfigMap:
```json
{
  "name": "k8s_apply",
  "arguments": {
    "yaml": "apiVersion: v1\nkind: ConfigMap\nmetadata:\n  name: app-config\ndata:\n  database_url: postgres://db:5432\n  cache_ttl: \"3600\""
  }
}
```

**Output Format:**
```
Successfully created Deployment/nginx
```

For updates:
```
Successfully updated Service/nginx
```

**Error Handling:**
- Invalid YAML → `Error: Invalid YAML - mapping values are not allowed here`
- Access denied → `Error: Access denied - check RBAC permissions`
- Validation failed → `Error: Deployment.apps "nginx" is invalid: spec.replicas: Invalid value`

---

### 4. k8s_delete

Delete a Kubernetes resource.

**Parameters:**
- `resource` (string, required) - Resource type (e.g., 'pod', 'deployment', 'service')
- `name` (string, required) - Resource name
- `namespace` (string, optional) - Namespace (omit for cluster-scoped resources)

**Returns:** Success message

**Examples:**

Delete a pod:
```json
{
  "name": "k8s_delete",
  "arguments": {
    "resource": "pod",
    "name": "nginx-7f456874f4-x9k2m",
    "namespace": "default"
  }
}
```

Delete a deployment:
```json
{
  "name": "k8s_delete",
  "arguments": {
    "resource": "deployment",
    "name": "old-api-server",
    "namespace": "production"
  }
}
```

Delete cluster-scoped resource:
```json
{
  "name": "k8s_delete",
  "arguments": {
    "resource": "clusterrole",
    "name": "deprecated-role"
  }
}
```

**Output Format:**
```
Successfully deleted pod/nginx-7f456874f4-x9k2m
```

**Error Handling:**
- Resource not found → `Error: Resource not found - pod/nginx-7f456874f4-x9k2m`
- Access denied → `Error: Access denied - check RBAC permissions`
- Deletion protected → `Error: Resource is protected by finalizer`

---

### 5. k8s_logs

Get logs from a pod.

**Parameters:**
- `name` (string, required) - Pod name
- `namespace` (string, optional) - Namespace (defaults to 'default')
- `container` (string, optional) - Container name (required for multi-container pods)
- `tail` (number, optional) - Number of lines to show from end of logs (default: 100)
- `previous` (boolean, optional) - Get logs from previous container instance (default: false)

**Returns:** Pod logs

**Examples:**

Get recent logs:
```json
{
  "name": "k8s_logs",
  "arguments": {
    "name": "api-server-5c7d8e6f4-q2m7k",
    "namespace": "production",
    "tail": 50
  }
}
```

Get logs from specific container:
```json
{
  "name": "k8s_logs",
  "arguments": {
    "name": "app-pod",
    "namespace": "default",
    "container": "sidecar",
    "tail": 200
  }
}
```

Get logs from previous container (after crash):
```json
{
  "name": "k8s_logs",
  "arguments": {
    "name": "crashing-pod",
    "namespace": "debug",
    "previous": true
  }
}
```

**Output Format:**
```
Logs for pod api-server-5c7d8e6f4-q2m7k:

2025-01-15T14:30:15Z INFO Starting API server on port 8080
2025-01-15T14:30:16Z INFO Database connection established
2025-01-15T14:30:20Z INFO Health check endpoint ready
2025-01-15T14:30:25Z INFO Received request: GET /api/users
```

With container name:
```
Logs for pod app-pod (container: sidecar):

2025-01-15T14:30:15Z [sidecar] Initializing proxy
2025-01-15T14:30:16Z [sidecar] Forwarding traffic to port 8080
```

**Error Handling:**
- Pod not found → `Error: Pod not found - api-server-5c7d8e6f4-q2m7k`
- Multi-container pod without container name → `Error: Multi-container pod. Please specify container name. Available: app, sidecar, init`
- Access denied → `Error: Access denied - check RBAC permissions`
- Container not ready → `Error: Container is not ready yet`

---

### 6. k8s_exec

Execute a command in a pod container.

**Parameters:**
- `name` (string, required) - Pod name
- `command` (string, required) - Command to execute (e.g., 'ls -la', 'env')
- `namespace` (string, optional) - Namespace (defaults to 'default')
- `container` (string, optional) - Container name (required for multi-container pods)

**Returns:** Command output

**Examples:**

List files:
```json
{
  "name": "k8s_exec",
  "arguments": {
    "name": "nginx-7f456874f4-x9k2m",
    "namespace": "default",
    "command": "ls -la /usr/share/nginx/html"
  }
}
```

Check environment variables:
```json
{
  "name": "k8s_exec",
  "arguments": {
    "name": "api-server-5c7d8e6f4-q2m7k",
    "namespace": "production",
    "command": "env | grep DATABASE"
  }
}
```

Execute in specific container:
```json
{
  "name": "k8s_exec",
  "arguments": {
    "name": "app-pod",
    "namespace": "default",
    "container": "sidecar",
    "command": "curl localhost:8080/health"
  }
}
```

Check process status:
```json
{
  "name": "k8s_exec",
  "arguments": {
    "name": "postgres-5c7d8e6f4-q2m7k",
    "namespace": "database",
    "command": "ps aux"
  }
}
```

**Output Format:**
```
Command output from pod nginx-7f456874f4-x9k2m:

total 12
drwxr-xr-x 2 root root 4096 Jan 15 10:30 .
drwxr-xr-x 3 root root 4096 Jan 15 10:30 ..
-rw-r--r-- 1 root root  612 Jan 15 10:30 index.html
```

With container name:
```
Command output from pod app-pod (container: sidecar):

{"status": "healthy", "uptime": 3600}
```

**Error Handling:**
- Pod not found → `Error: Pod not found - nginx-7f456874f4-x9k2m`
- Multi-container pod without container name → `Error: Multi-container pod. Please specify container name. Available: app, sidecar`
- Access denied → `Error: Access denied - check RBAC permissions`
- Command failed → Returns command stderr output

---

## Configuration

### RBAC Permissions

The Kubernetes Tool requires a ServiceAccount with appropriate RBAC permissions. The level of access determines what resources the agent can manage.

#### Minimal Permissions (Read-Only)
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: k8s-tool-readonly
  namespace: default
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: k8s-tool-readonly
  namespace: default
rules:
- apiGroups: ["", "apps", "batch"]
  resources: ["pods", "deployments", "services", "jobs", "configmaps"]
  verbs: ["get", "list"]
- apiGroups: [""]
  resources: ["pods/log"]
  verbs: ["get"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: k8s-tool-readonly
  namespace: default
subjects:
- kind: ServiceAccount
  name: k8s-tool-readonly
  namespace: default
roleRef:
  kind: Role
  name: k8s-tool-readonly
  apiGroup: rbac.authorization.k8s.io
```

#### Standard Permissions (Namespace Management)
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: k8s-tool
  namespace: default
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: k8s-tool
  namespace: default
rules:
- apiGroups: ["", "apps", "batch", "networking.k8s.io"]
  resources: ["*"]
  verbs: ["get", "list", "create", "update", "patch", "delete"]
- apiGroups: [""]
  resources: ["pods/log", "pods/exec"]
  verbs: ["get", "create"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: k8s-tool
  namespace: default
subjects:
- kind: ServiceAccount
  name: k8s-tool
  namespace: default
roleRef:
  kind: Role
  name: k8s-tool
  apiGroup: rbac.authorization.k8s.io
```

#### Cluster-Wide Permissions (Full Access)
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: k8s-tool-admin
  namespace: default
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: k8s-tool-admin
rules:
- apiGroups: ["*"]
  resources: ["*"]
  verbs: ["*"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: k8s-tool-admin
subjects:
- kind: ServiceAccount
  name: k8s-tool-admin
  namespace: default
roleRef:
  kind: ClusterRole
  name: k8s-tool-admin
  apiGroup: rbac.authorization.k8s.io
```

### Environment Variables

The Kubernetes Tool uses in-cluster configuration automatically. No environment variables are required when running inside a Kubernetes cluster.

For local development with kubeconfig:
- Tool automatically falls back to `~/.kube/config`
- No additional configuration needed

---

## Deployment

### As a LanguageTool

```yaml
apiVersion: langop.io/v1alpha1
kind: LanguageTool
metadata:
  name: k8s
spec:
  image: ghcr.io/language-operator/k8s-tool:latest
  deploymentMode: service
  port: 80
  type: mcp
  authRequired: true
  # ServiceAccount determines permissions
  serviceAccount: k8s-tool
```

### Agent Configuration

```yaml
apiVersion: langop.io/v1alpha1
kind: LanguageAgent
metadata:
  name: cluster-manager
spec:
  instructions: |
    You are a Kubernetes cluster manager.
    Monitor deployments and ensure they remain healthy.
    Scale resources based on load.
  tools:
  - k8s
  - email
```

### With Specific Permissions

```yaml
apiVersion: langop.io/v1alpha1
kind: LanguageTool
metadata:
  name: k8s-readonly
spec:
  image: ghcr.io/language-operator/k8s-tool:latest
  deploymentMode: service
  port: 80
  type: mcp
  authRequired: true
  serviceAccount: k8s-tool-readonly
```

---

## Security Model

### RBAC-Based Access Control

All Kubernetes operations are subject to RBAC permissions:

1. **ServiceAccount Assignment**: Tool runs with specific ServiceAccount
2. **Role/ClusterRole**: Defines allowed operations and resources
3. **RoleBinding/ClusterRoleBinding**: Links ServiceAccount to permissions
4. **Namespace Isolation**: Roles limit access to specific namespaces

### Principle of Least Privilege

Agents should only have the minimum permissions needed:

```yaml
# ❌ Bad - overly broad permissions
rules:
- apiGroups: ["*"]
  resources: ["*"]
  verbs: ["*"]

# ✅ Good - specific permissions
rules:
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["get", "list", "update"]
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list"]
- apiGroups: [""]
  resources: ["pods/log"]
  verbs: ["get"]
```

### Audit Logging

All Kubernetes API calls are logged by the Kubernetes audit system:

```yaml
# Enable audit logging in cluster
apiVersion: audit.k8s.io/v1
kind: Policy
rules:
- level: RequestResponse
  resources:
  - group: ""
    resources: ["pods", "services"]
  - group: "apps"
    resources: ["deployments"]
```

### Network Isolation

The k8s tool operates entirely within the cluster and requires no external network access. It communicates directly with the Kubernetes API server via in-cluster service discovery.

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
      "name": "k8s-tool",
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
curl http://k8s.default.svc.cluster.local/health
```

Response:
```json
{
  "status": "ok",
  "service": "k8s-tool",
  "version": "1.0.0"
}
```

---

## Testing

### Manual Testing

```bash
# List pods
curl -X POST http://localhost:8080/mcp \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc":"2.0",
    "id":1,
    "method":"tools/call",
    "params":{
      "name":"k8s_list",
      "arguments":{"resource":"pods","namespace":"default"}
    }
  }'

# Get a specific deployment
curl -X POST http://localhost:8080/mcp \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc":"2.0",
    "id":2,
    "method":"tools/call",
    "params":{
      "name":"k8s_get",
      "arguments":{"resource":"deployment","name":"nginx","namespace":"default"}
    }
  }'

# Get pod logs
curl -X POST http://localhost:8080/mcp \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc":"2.0",
    "id":3,
    "method":"tools/call",
    "params":{
      "name":"k8s_logs",
      "arguments":{"name":"nginx-7f456874f4-x9k2m","namespace":"default","tail":50}
    }
  }'
```

### Automated Tests

```bash
cd k8s
bundle install
bundle exec rspec
```

---

## Common Patterns

### Self-Healing Deployment

```yaml
apiVersion: langop.io/v1alpha1
kind: LanguageAgent
metadata:
  name: self-healer
spec:
  instructions: |
    Monitor my own deployment health every 5 minutes.
    If unhealthy, attempt to fix by:
    1. Checking logs for errors
    2. Restarting failed pods
    3. Scaling replicas if needed
    4. Emailing admin if unable to resolve
  tools:
  - k8s
  - email
  - cron
```

### Dynamic Scaling

```yaml
apiVersion: langop.io/v1alpha1
kind: LanguageAgent
metadata:
  name: smart-scaler
spec:
  instructions: |
    Monitor API server pods.
    When average CPU > 70%, scale up.
    When average CPU < 30% for 10 minutes, scale down.
    Maintain 2-10 replicas.
  tools:
  - k8s
```

### Deployment Automation

```yaml
apiVersion: langop.io/v1alpha1
kind: LanguageAgent
metadata:
  name: deployer
spec:
  instructions: |
    When new deployment manifests appear in workspace,
    validate them and apply to the staging namespace.
    Monitor for 5 minutes and report status via email.
  tools:
  - k8s
  - workspace
  - email
```

### Log Analysis

```yaml
apiVersion: langop.io/v1alpha1
kind: LanguageAgent
metadata:
  name: log-analyzer
spec:
  instructions: |
    Fetch logs from all pods labeled 'app=api'.
    Analyze for errors, warnings, and performance issues.
    Create summary report and save to workspace.
    Email critical issues immediately.
  tools:
  - k8s
  - workspace
  - email
```

---

## Troubleshooting

### Common Issues

**"Error: Access denied - check RBAC permissions"**
- Cause: ServiceAccount lacks required RBAC permissions
- Solution:
  - Verify ServiceAccount is assigned to LanguageTool
  - Check Role/ClusterRole has required verbs and resources
  - Ensure RoleBinding/ClusterRoleBinding exists
  - Review Kubernetes audit logs for specific denial reason

**"Error: Resource not found"**
- Cause: Resource doesn't exist or wrong namespace
- Solution:
  - Verify resource name is correct
  - Check if resource is in expected namespace
  - Use `k8s_list` to find available resources
  - Ensure resource hasn't been deleted

**"Error: Failed to initialize Kubernetes client"**
- Cause: Unable to connect to Kubernetes API
- Solution:
  - Verify pod is running in Kubernetes cluster
  - Check ServiceAccount token is mounted at `/var/run/secrets/kubernetes.io/serviceaccount/token`
  - Ensure Kubernetes API server is accessible
  - Review network policies

**"Error: Multi-container pod. Please specify container name"**
- Cause: Pod has multiple containers but no container name provided
- Solution:
  - Use `k8s_get` to view pod spec and see container names
  - Provide `container` parameter with specific container name
  - List available containers in error message

**"Error: Invalid YAML"**
- Cause: Malformed YAML in `k8s_apply`
- Solution:
  - Validate YAML syntax
  - Check indentation (use spaces, not tabs)
  - Ensure all required fields are present
  - Use YAML linter before applying

---

## Performance Considerations

### API Rate Limiting

The Kubernetes API server has rate limits:

- **Default**: 200 QPS per client
- **Burst**: 400 requests
- **Recommendation**: Implement delays between operations for bulk changes

### Resource Limits

```yaml
apiVersion: langop.io/v1alpha1
kind: LanguageTool
metadata:
  name: k8s
spec:
  image: ghcr.io/language-operator/k8s-tool:latest
  resources:
    requests:
      memory: "128Mi"
      cpu: "100m"
    limits:
      memory: "256Mi"
      cpu: "500m"
```

### List Operation Efficiency

- Use `limit` parameter to control result size
- Use `selector` to filter results server-side
- Avoid listing all resources across all namespaces frequently

### Watch vs Poll

For real-time monitoring, Kubernetes Watch API is more efficient than polling:

```ruby
# Use k8s-ruby watch capability (future enhancement)
api_client.watch(labelSelector: 'app=nginx') do |event|
  # Handle event
end
```

---

## Best Practices

1. **Use Least Privilege**: Grant only necessary RBAC permissions
2. **Namespace Isolation**: Limit agents to specific namespaces when possible
3. **Label Resources**: Use labels for easy filtering and selection
4. **Validate Before Apply**: Check YAML syntax and test in staging
5. **Monitor Operations**: Track what agents are doing via audit logs
6. **Handle Errors Gracefully**: Always check operation results
7. **Use Selectors**: Filter resources with label selectors for efficiency
8. **Set Resource Limits**: Prevent runaway resource consumption
9. **Implement Timeouts**: Don't wait indefinitely for operations
10. **Document Intent**: Use annotations to explain agent actions

---

## Advanced Usage

### Custom Resource Definitions (CRDs)

The k8s tool works with CRDs just like native resources:

```json
{
  "name": "k8s_get",
  "arguments": {
    "resource": "languageagent",
    "name": "my-agent",
    "namespace": "default"
  }
}
```

### Multi-Step Workflows

```yaml
apiVersion: langop.io/v1alpha1
kind: LanguageAgent
metadata:
  name: release-manager
spec:
  instructions: |
    To deploy a new release:
    1. Use k8s_get to fetch current deployment
    2. Update image tag in YAML
    3. Use k8s_apply to apply updated deployment
    4. Use k8s_logs to monitor rollout
    5. If errors, rollback using k8s_apply with previous version
    6. Email status report when complete
  tools:
  - k8s
  - email
```

### Cross-Namespace Operations

```yaml
apiVersion: langop.io/v1alpha1
kind: LanguageAgent
metadata:
  name: multi-namespace-manager
spec:
  instructions: |
    Coordinate deployments across dev, staging, and prod namespaces.
    Ensure consistency and propagate changes appropriately.
  tools:
  - k8s
  - workspace
```

---

## Version

**Current Version:** 1.0.0

**MCP Protocol:** 2024-11-05

**Language Operator Compatibility:** v0.2.0+

**k8s-ruby Version:** ~> 0.11

---

## License

MIT License - see [LICENSE](../LICENSE)
