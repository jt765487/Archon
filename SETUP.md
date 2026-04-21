# Archon Setup Guide

This guide will help you get Archon up and running.

## Quick Start

### 1. Environment Variables

Copy `.env.example` to `.env` and configure the necessary settings:

```bash
cp .env.example .env
```

**Minimum required for basic usage:**

```bash
# AI Assistant (choose one)
CLAUDE_USE_GLOBAL_AUTH=true  # Recommended: use `claude /login`
# OR set explicit token:
# CLAUDE_CODE_OAUTH_TOKEN=your_token_here

# Default assistant
DEFAULT_AI_ASSISTANT=claude
```

**Optional - Platform integrations:**

- **GitHub**: `GH_TOKEN` (for GitHub CLI and commands)
- **Slack**: `SLACK_BOT_TOKEN`, `SLACK_APP_TOKEN`
- **Telegram**: `TELEGRAM_BOT_TOKEN`
- **Discord**: `DISCORD_BOT_TOKEN`

### 2. Install Claude Code (if not already installed)

```bash
# Anthropic's recommended installer
curl -fsSL https://claude.ai/install.sh | bash

# Verify installation
claude --version
```

The binary should be at `~/.local/bin/claude`. Archon will auto-detect it.

### 3. Initialize Archon Directory

Archon uses `~/.archon/` for all user-level data:

```bash
# Archon auto-creates this on first run, but you can verify:
ls -la ~/.archon/
```

### 4. Start the Server

```bash
# Development mode (hot reload)
bun run dev

# This starts both:
# - Backend server on port 3090
# - Web UI on port 5173
```

**Or run separately:**

```bash
# Backend only
bun run dev:server

# Frontend only
bun run dev:web
```

### 5. Access the Web UI

Open your browser to: **http://localhost:5173**

You can also use the CLI directly:

```bash
# List available workflows
bun run cli workflow list

# Start a conversation
bun run cli workflow run assist "What does the orchestrator do?"

# Check status
bun run cli workflow status
```

## Configuration

### AI Assistants

**Claude** (recommended):

```yaml
# ~/.archon/config.yaml
assistants:
  claude:
    model: sonnet # or 'opus', 'haiku', 'claude-*', 'inherit'
    settingSources:
      - project # Only project-level CLAUDE.md (default)
      # - user     # Optional: also load ~/.claude/CLAUDE.md
```

**Codex**:

```yaml
assistants:
  codex:
    model: gpt-5.3-codex
    modelReasoningEffort: medium # minimal | low | medium | high | xhigh
    webSearchMode: live # disabled | cached | live
```

**Pi** (community provider - ~20 LLM backends):

```yaml
assistants:
  pi:
    model: anthropic/claude-haiku-4-5 # provider/model format
```

Set `DEFAULT_AI_ASSISTANT=claude` (or `codex`, `pi`) in `.env`.

### Database

**SQLite** (default, zero setup):

- Data stored at `~/.archon/archon.db`
- No configuration needed

**PostgreSQL** (optional, for heavy usage):

```bash
# Start PostgreSQL container
docker compose --profile with-db up -d postgres

# Set in .env
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/remote_coding_agent

# Run migrations
psql $DATABASE_URL < migrations/000_combined.sql
```

### Project Configuration

Each repository can have its own `.archon/` directory:

```
.my-project/
├── .archon/
│   ├── config.yaml      # Project-specific config
│   ├── commands/        # Custom commands
│   ├── workflows/       # Workflow definitions
│   └── scripts/         # Custom scripts
```

**Example `.archon/config.yaml`:**

```yaml
worktree:
  baseBranch: dev # Default branch for worktrees

docs:
  path: docs # Documentation directory (default: docs/)

assistants:
  claude:
    model: sonnet # Override global default
```

## Workflows

### List Available Workflows

```bash
# Via CLI
bun run cli workflow list

# Via Web UI
# Navigate to Workflows tab
```

### Run a Workflow

```bash
# Basic usage
bun run cli workflow run assist "Your question here"

# With explicit branch name
bun run cli workflow run implement --branch feature-xyz "Add authentication"

# Without worktree isolation (live checkout)
bun run cli workflow run quick-fix --no-worktree "Fix typo"
```

### Workflow Types

- **`assist`**: General AI assistance (read-only)
- **`plan`**: Create implementation plan
- **`implement`**: Make code changes (creates worktree)
- **`quick-fix`**: Fast fixes without isolation
- **`review`**: Code review
- **`test`**: Run tests

## Git Worktree Isolation

Archon automatically creates isolated worktrees for workflows that make changes:

```bash
# List active worktrees
bun run cli isolation list

# Clean up stale worktrees (>7 days)
bun run cli isolation cleanup

# Clean up merged worktrees
bun run cli isolation cleanup --merged
```

## Validation

Before committing changes:

```bash
# Run all checks
bun run validate

# Individual checks
bun run type-check
bun run lint
bun run format
bun test
```

## Troubleshooting

### Claude Code Not Found

```bash
# Verify installation
which claude

# If not found, install:
curl -fsSL https://claude.ai/install.sh | bash

# Or set explicit path in .archon/config.yaml:
assistants:
  claude:
    claudeBinaryPath: /absolute/path/to/claude
```

### Permission Errors

```bash
# Ensure scripts are executable
chmod +x scripts/*.sh

# Check git config
git config --global user.email "you@example.com"
git config --global user.name "Your Name"
```

### Database Errors

```bash
# Check SQLite file exists
ls -la ~/.archon/archon.db

# For PostgreSQL, verify connection
psql $DATABASE_URL -c "SELECT 1"
```

### Port Already in Use

```bash
# Change port
PORT=4000 bun run dev

# Or find and kill the process
lsof -ti:3090 | xargs kill -9
```

## Next Steps

1. **Explore Workflows**: Check `.archon/workflows/` for available workflows
2. **Create Custom Commands**: Add files to `.archon/commands/`
3. **Build Custom Workflows**: Create YAML files in `.archon/workflows/`
4. **Integrate Platforms**: Configure Slack, Telegram, or GitHub in `.env`

## Documentation

- **Main Docs**: See `packages/docs-web/src/content/docs/`
- **CLI Help**: `bun run cli --help`
- **Workflow Syntax**: See workflow YAML files in `.archon/workflows/`

## Support

- **Issues**: Report on GitHub
- **Documentation**: Visit the Web UI docs tab
- **Community**: Join discussions on GitHub Discussions
