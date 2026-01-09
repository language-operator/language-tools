.PHONY: help build validate clean build-all push-all

# Default target
help:
	@echo "Language Operator Tools - Makefile"
	@echo ""
	@echo "Targets:"
	@echo "  build        - Compile index.yaml from tool manifests"
	@echo "  validate     - Validate all tool manifests"
	@echo "  build-all    - Build all tool Docker images"
	@echo "  push-all     - Push all tool Docker images"
	@echo "  clean        - Remove generated index.yaml"
	@echo ""
	@echo "Individual tool targets:"
	@echo "  k8s-build        - Build k8s tool image"
	@echo "  k8s-push         - Push k8s tool image"
	@echo "  email-build      - Build email tool image"
	@echo "  email-push       - Push email tool image"
	@echo "  web-build        - Build web tool image"
	@echo "  web-push         - Push web tool image"
	@echo "  filesystem-build - Build filesystem tool image"
	@echo "  filesystem-push  - Push filesystem tool image"
	@echo "  cron-build       - Build cron tool image"
	@echo "  cron-push        - Push cron tool image"

# Compile index.yaml from all tool manifests
build:
	@echo "Compiling tool registry index..."
	@ruby scripts/compile-index.rb

# Validate manifests without generating index
validate:
	@echo "Validating tool manifests..."
	@ruby scripts/compile-index.rb

# Clean generated files
clean:
	@echo "Cleaning generated files..."
	@rm -f index.yaml
	@echo "✓ Removed index.yaml"

# Build all tool images
build-all:
	@echo "Building all tool images..."
	@$(MAKE) -C k8s build
	@$(MAKE) -C email build
	@$(MAKE) -C web build
	@$(MAKE) -C filesystem build
	@$(MAKE) -C cron build
	@echo "✓ All tools built successfully"

# Push all tool images
push-all:
	@echo "Pushing all tool images..."
	@$(MAKE) -C k8s push
	@$(MAKE) -C email push
	@$(MAKE) -C web push
	@$(MAKE) -C filesystem push
	@$(MAKE) -C cron push
	@echo "✓ All tools pushed successfully"

# Individual tool targets
k8s-build:
	@$(MAKE) -C k8s build

k8s-push:
	@$(MAKE) -C k8s push

email-build:
	@$(MAKE) -C email build

email-push:
	@$(MAKE) -C email push

web-build:
	@$(MAKE) -C web build

web-push:
	@$(MAKE) -C web push

filesystem-build:
	@$(MAKE) -C filesystem build

filesystem-push:
	@$(MAKE) -C filesystem push

cron-build:
	@$(MAKE) -C cron build

cron-push:
	@$(MAKE) -C cron push
