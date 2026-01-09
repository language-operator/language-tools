#!/bin/bash

# Script to install git hooks for language-tools repository
# Run this after cloning the repository: ./githooks/install-hooks.sh

set -e

REPO_ROOT=$(git rev-parse --show-toplevel)
HOOKS_DIR="$REPO_ROOT/.githooks"
GIT_HOOKS_DIR="$REPO_ROOT/.git/hooks"

echo "Installing git hooks..."

# Create hooks directory if it doesn't exist
mkdir -p "$GIT_HOOKS_DIR"

# Install pre-commit hook
if [ -f "$HOOKS_DIR/pre-commit" ]; then
    cp "$HOOKS_DIR/pre-commit" "$GIT_HOOKS_DIR/pre-commit"
    chmod +x "$GIT_HOOKS_DIR/pre-commit"
    echo "✓ Installed pre-commit hook"
else
    echo "⚠ No pre-commit hook found in $HOOKS_DIR"
fi

echo "Git hooks installation complete!"
echo ""
echo "The pre-commit hook will automatically:"
echo "- Rebuild index.yaml when manifest.yaml files change"
echo "- Stage the updated index.yaml for commit"
echo ""
echo "To disable hooks temporarily: git commit --no-verify"