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
	@echo "  thinking-build   - Build thinking tool image"
	@echo "  thinking-push    - Push thinking tool image"
	@echo "  memory-build     - Build memory tool image"
	@echo "  memory-push      - Push memory tool image"
	@echo "  time-build       - Build time tool image"
	@echo "  time-push        - Push time tool image"
	@echo "  shell-build      - Build shell tool image"
	@echo "  shell-push       - Push shell tool image"

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
	@$(MAKE) -C thinking build
	@$(MAKE) -C memory build
	@$(MAKE) -C time build
	@$(MAKE) -C shell build
	@echo "✓ All tools built successfully"

# Push all tool images
push-all:
	@echo "Pushing all tool images..."
	@$(MAKE) -C k8s push
	@$(MAKE) -C email push
	@$(MAKE) -C web push
	@$(MAKE) -C filesystem push
	@$(MAKE) -C thinking push
	@$(MAKE) -C memory push
	@$(MAKE) -C time push
	@$(MAKE) -C shell push
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

thinking-build:
	@$(MAKE) -C thinking build

thinking-push:
	@$(MAKE) -C thinking push

memory-build:
	@$(MAKE) -C memory build

memory-push:
	@$(MAKE) -C memory push

time-build:
	@$(MAKE) -C time build

time-push:
	@$(MAKE) -C time push

shell-build:
	@$(MAKE) -C shell build

shell-push:
	@$(MAKE) -C shell push

