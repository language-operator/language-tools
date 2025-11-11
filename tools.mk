# Shared Makefile for Language Operator Tools
# Include this file from individual tool Makefiles
#
# Required variables to be set by including Makefile:
#   IMAGE_NAME - Full image name (e.g., ghcr.io/language-operator/email-tool)
#   TOOL_NAME  - Tool name for display (e.g., email, web)
#
# Optional variables:
#   IMAGE_TAG  - Image tag (default: latest)
#   EXTRA_DOCKER_ENV - Additional docker environment variables for run/shell targets

IMAGE_TAG ?= latest
IMAGE_FULL := $(IMAGE_NAME):$(IMAGE_TAG)

# Default target
.PHONY: help
help:
	@echo "Available targets:"
	@echo "  build     - Build the Docker image"
	@echo "  scan      - Scan the Docker image with Trivy"
	@echo "  shell     - Run the image and exec into it with an interactive shell"
	@echo "  env       - Display sorted list of environment variables in the image"
	@echo "  run       - Run the $(TOOL_NAME) MCP server on port 8080"
	@echo "  spec      - Run RSpec unit tests"
	@echo "  test      - Run the server and test the $(TOOL_NAME) endpoints"
	@echo "  lint      - Run RuboCop linter"
	@echo "  lint-fix  - Auto-fix RuboCop issues"
	@echo "  doc       - Generate YARD documentation"
	@echo "  doc-serve - Generate and serve YARD documentation"
	@echo "  doc-clean - Remove generated documentation"
	@echo "  clean     - Remove all generated files"

# Build the Docker image
.PHONY: build
build:
	docker build \
		-t $(IMAGE_FULL) .

# Scan the Docker image with Trivy
.PHONY: scan
scan:
	trivy image $(IMAGE_FULL)

# Run the image and exec into it with an interactive shell
.PHONY: shell
shell:
	docker run --rm -it $(EXTRA_DOCKER_ENV) $(IMAGE_FULL) /bin/sh

# Display sorted list of environment variables in the image
.PHONY: env
env:
	docker run --rm $(IMAGE_FULL) /bin/sh -c 'env | sort'

# Run the MCP server
.PHONY: run
run:
	docker run --rm -p 8080:80 $(EXTRA_DOCKER_ENV) --name $(TOOL_NAME)-server $(IMAGE_FULL)

# Run RSpec unit tests
.PHONY: spec
spec:
	@echo "Running RSpec unit tests..."
	bundle exec rspec --format documentation

# Lint Ruby code
.PHONY: lint
lint:
	@echo "Running RuboCop linter..."
	bundle exec rubocop

# Auto-fix linting issues
.PHONY: lint-fix
lint-fix:
	@echo "Auto-fixing RuboCop issues..."
	bundle exec rubocop -A

# Generate documentation
.PHONY: doc
doc:
	@echo "Generating documentation with YARD..."
	bundle exec yard doc
	@echo "Documentation generated in doc/"

# Serve documentation
.PHONY: doc-serve
doc-serve: doc
	@echo "Serving documentation at http://localhost:8808"
	bundle exec yard server --reload

# Clean documentation
.PHONY: doc-clean
doc-clean:
	@echo "Cleaning documentation..."
	rm -rf doc/ .yardoc

# Clean all generated files
.PHONY: clean
clean: doc-clean
	@echo "Cleaning all generated files..."
	rm -rf vendor/ .bundle/ Gemfile.lock
