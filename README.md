# Language Operator Tools

Official MCP (Model Context Protocol) tools for the [Language Operator](https://github.com/language-operator/language-operator) project.

This repository contains MCP server implementations that are compatible with the Language Operator system for Kubernetes-native AI agent orchestration.

## Available Tools

### 🌐 [Web Tool](web/)
HTTP/web interaction tools for agents:
- **web_search** - Search the web using DuckDuckGo
- **web_fetch** - Fetch and convert web pages to markdown
- **web_headers** - Retrieve HTTP headers from URLs
- **web_status** - Check HTTP status codes

[View Web Tool Documentation →](web/README.md)

### 📧 [Email Tool](email/)
SMTP email capabilities for agents:
- **send_email** - Send emails via SMTP
- **test_smtp** - Test SMTP connection and authentication
- **email_config** - Display current email configuration

[View Email Tool Documentation →](email/README.md)

## Building MCP Servers for Language Operator

### Overview

Language Operator tools are MCP servers packaged as Docker containers that extend the Language Operator SDK. They expose capabilities to AI agents running in Kubernetes through a standardized protocol.

### Requirements

To build an MCP server compatible with Language Operator:

1. **Base Image**: Extend from `git.theryans.io/language-operator/base:latest`
2. **SDK Integration**: Use the `language-operator` gem (~> 0.1.x)
3. **Ruby Version**: Ruby 3.4+
4. **Tool Definition**: Implement tools using the Language Operator DSL
5. **Server Entry Point**: Use `LanguageOperator::ToolLoader.start` or implement custom server

### Quick Start

#### 1. Create a Gemfile

```ruby
source 'https://rubygems.org'
source 'https://git.theryans.io/api/packages/language-operator/rubygems'

gem 'language-operator', '~> 0.1.1'
# Add your tool-specific dependencies here
```

#### 2. Define Your Tools

Create a `tools/` directory with your tool definitions:

```ruby
# tools/my_tool.rb
require 'language-operator'

tool "my_tool_name" do
  description "What this tool does"

  parameter "input_text" do
    type :string
    required true
    description "Input parameter description"
  end

  parameter "optional_flag" do
    type :boolean
    required false
    description "Optional parameter"
  end

  execute do |params|
    # Your tool logic here
    result = process(params['input_text'])

    {
      content: [
        {
          type: "text",
          text: "Result: #{result}"
        }
      ]
    }
  end
end
```

#### 3. Create a Dockerfile

```dockerfile
FROM git.theryans.io/language-operator/base:latest

# Install Ruby and build dependencies
RUN apk add --no-cache \
    ruby \
    ruby-dev \
    ruby-bundler \
    build-base

WORKDIR /app

# Copy Gemfile and install dependencies
COPY Gemfile /app/

# Install gems (credentials inherited from base image)
RUN bundle install --no-cache

# Copy your tools
COPY tools/ /mcp/

# Ensure directories are owned by langop user
RUN chown -R langop:langop /mcp /app

# Switch to langop user
USER langop

# Expose default port
EXPOSE 80

# Set environment variables
ENV PORT=80
ENV RACK_ENV=production

# Start the MCP server
CMD ["ruby", "-r", "language_operator/tool_loader", "-e", "LanguageOperator::ToolLoader.start"]
```

#### 4. Build and Test

```bash
# Build your tool image
docker build -t my-tool:latest .

# Run locally for testing
docker run -p 3000:80 my-tool:latest

# Test with curl
curl http://localhost:3000/tools/list
```

### Tool DSL Reference

The Language Operator DSL provides these building blocks:

#### Parameter Types
- `:string` - Text input
- `:integer` - Numeric input
- `:boolean` - True/false flags
- `:array` - Lists of values
- `:object` - Structured data

#### Parameter Properties
- `required true/false` - Whether parameter is mandatory
- `description "text"` - Help text for the parameter
- `default value` - Default value if not provided

#### Execution Block
The `execute` block receives a `params` hash and should return:
```ruby
{
  content: [
    {
      type: "text",      # or "image", "resource"
      text: "Result"     # actual content
    }
  ]
}
```

### Authentication & Registry Access

The base image contains pre-configured credentials for accessing the private gem registry:

- **Gem Registry**: `https://git.theryans.io/api/packages/language-operator/rubygems`
- **Authentication**: Handled automatically via `BUNDLE_GIT__THERYANS__IO` environment variable
- **No build-args needed**: Credentials are baked into the base image

### Testing Your Tools

Create RSpec tests following this pattern:

```ruby
# spec/tools/my_tool_spec.rb
require 'spec_helper'

RSpec.describe 'my_tool_name' do
  let(:tool) { LanguageOperator::ToolRegistry.get('my_tool_name') }

  it 'processes input correctly' do
    result = tool.execute({
      'input_text' => 'test input'
    })

    expect(result[:content]).not_to be_empty
    expect(result[:content].first[:text]).to include('Result')
  end
end
```

Run tests:
```bash
bundle exec rspec
```

### Kubernetes Integration

Deploy your tool using a `LanguageTool` custom resource:

```yaml
apiVersion: langop.io/v1alpha1
kind: LanguageTool
metadata:
  name: my-tool
  namespace: my-namespace
spec:
  image: git.theryans.io/language-operator/my-tool:latest
  deploymentMode: sidecar  # or 'service'
  port: 80
  egress:
  - description: Allow HTTPS to external APIs
    to:
      dns:
      - "*.example.com"
    ports:
    - port: 443
      protocol: TCP
```

The operator will:
1. Deploy your tool container
2. Register it with agents in the same namespace
3. Configure network policies based on `egress` rules
4. Inject it as a sidecar or expose it as a service

### Best Practices

1. **Keep tools focused** - Each tool should do one thing well
2. **Validate inputs** - Use `required` and type checking
3. **Handle errors gracefully** - Return informative error messages
4. **Write tests** - Ensure reliability with comprehensive test coverage
5. **Document parameters** - Clear descriptions help agents use tools correctly
6. **Follow Ruby standards** - Use RuboCop and YARD for code quality
7. **Secure credentials** - Never hardcode secrets; use environment variables
8. **Minimize dependencies** - Smaller images are faster and more secure

### Development Workflow

1. **Local Development**
   ```bash
   bundle install
   bundle exec rspec
   bundle exec rubocop
   ```

2. **Build Image**
   ```bash
   make build
   ```

3. **Test in Kubernetes**
   ```bash
   kubectl apply -f my-tool.yaml
   kubectl get languagetools
   ```

4. **Monitor Logs**
   ```bash
   kubectl logs -l app=my-tool -f
   ```

### Resources

- [Language Operator Documentation](https://github.com/language-operator/language-operator)
- [Language Operator SDK](https://github.com/language-operator/sdk)
- [MCP Specification](https://spec.modelcontextprotocol.io/)
- [Web Tool Example](web/)
- [Email Tool Example](email/)

### Contributing

Contributions are welcome! Please:
1. Fork this repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

### License

See [LICENSE](LICENSE) file for details.