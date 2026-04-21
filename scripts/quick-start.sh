#!/bin/bash
# Archon Quick Start Script
# This script helps you get started with Archon

set -e

echo "🚀 Archon Quick Start"
echo "===================="
echo ""

# Check prerequisites
echo "✅ Checking prerequisites..."

# Check Bun
if ! command -v bun &> /dev/null; then
    echo "❌ Bun is not installed. Please install Bun first:"
    echo "   curl -fsSL https://bun.sh/install | bash"
    exit 1
fi
echo "   Bun: $(bun --version)"

# Check Claude Code
if ! command -v claude &> /dev/null; then
    echo "⚠️  Claude Code not found. Installing..."
    curl -fsSL https://claude.ai/install.sh | bash
else
    echo "   Claude Code: $(claude --version | head -1)"
fi

# Check Git
if ! command -v git &> /dev/null; then
    echo "❌ Git is not installed"
    exit 1
fi
echo "   Git: $(git --version)"

echo ""
echo "📦 Installing dependencies..."
bun install

echo ""
echo "⚙️  Setting up environment..."

if [ ! -f .env ]; then
    echo "   Creating .env from .env.example..."
    cp .env.example .env
    echo "   ⚠️  Please configure your AI assistant credentials in .env"
    echo "      - For Claude: Set CLAUDE_USE_GLOBAL_AUTH=true (recommended)"
    echo "      - Or set CLAUDE_CODE_OAUTH_TOKEN manually"
else
    echo "   .env already exists"
fi

echo ""
echo "🔍 Validating setup..."

# Check if workflows can be loaded
if bun run cli workflow list > /dev/null 2>&1; then
    echo "   ✅ Workflows loaded successfully"
else
    echo "   ⚠️  Warning: Could not load workflows"
fi

echo ""
echo "🎉 Setup complete!"
echo ""
echo "Next steps:"
echo "  1. Configure your AI assistant in .env:"
echo "     - Set CLAUDE_USE_GLOBAL_AUTH=true (recommended)"
echo "     - Or add your Claude API token"
echo ""
echo "  2. Start the server:"
echo "     bun run dev"
echo ""
echo "  3. Open the Web UI:"
echo "     http://localhost:5173"
echo ""
echo "  Or use the CLI:"
echo "     bun run cli workflow list"
echo "     bun run cli workflow run assist \"Hello!\""
echo ""
echo "For more information, see SETUP.md"
