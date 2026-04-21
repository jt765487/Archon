# Pi-Only Configuration

This Archon instance is configured to use **only the Pi provider** (`@mariozechner/pi-coding-agent`) for all AI operations.

## What is Pi?

Pi is a unified coding agent harness that supports ~20 LLM backends through a single interface:

- **Anthropic**: Claude Sonnet, Opus, Haiku
- **OpenAI**: GPT-4.1, GPT-4o, etc.
- **Google**: Gemini 2.5 Pro, etc.
- **Others**: Groq, Mistral, Cerebras, xAI, OpenRouter, HuggingFace, and more

## Configuration

### Environment Variables (`.env`)

```bash
# Default AI Assistant - set to Pi
DEFAULT_AI_ASSISTANT=pi

# Pi backend API keys (optional - can also use `pi /login`)
# ANTHROPIC_API_KEY=...   # For anthropic/* models
# OPENAI_API_KEY=...      # For openai/* models
# GEMINI_API_KEY=...      # For google/* models
# GROQ_API_KEY=...        # For groq/* models
# MISTRAL_API_KEY=...     # For mistral/* models
# OPENROUTER_API_KEY=...  # For openrouter/* models
# etc.
```

### Global Configuration (`~/.archon/config.yaml`)

```yaml
# Default assistant is Pi
defaultAssistant: pi

assistants:
  pi:
    # Default model for all workflows
    # Format: <provider-id>/<model-id>
    model: vllm/Intel/Qwen3.5-122B-A10B-int4-AutoRound

worktree:
  baseBranch: dev

docs:
  path: packages/docs-web/src/content/docs
```

## Using Pi with Different Models

### Model Naming Convention

Pi uses the format: `<provider-id>/<model-id>`

**Examples:**

- `anthropic/claude-sonnet-4-5`
- `anthropic/claude-haiku-4-5`
- `openai/gpt-4.1`
- `google/gemini-2.5-pro`
- `groq/llama-3.3-70b`
- `mistral/mistral-large`
- `openrouter/qwen/qwen3-coder`

### Setting Model Per-Workflow

In workflow YAML:

```yaml
name: my-workflow
provider: pi
model: anthropic/claude-sonnet-4-5 # Override default

nodes:
  - id: task
    prompt: Do something
```

### Setting Model Per-Node

```yaml
name: my-workflow
provider: pi

nodes:
  - id: classify
    provider: pi
    model: openai/gpt-4.1-mini # Fast, cheap model

  - id: complex-task
    provider: pi
    model: anthropic/claude-sonnet-4-5 # More capable model
```

## Authentication

**Your Setup: Local Model via Remote Host**

You're using a locally-hosted model (`vllm/Intel/Qwen3.5-122B-A10B-int4-AutoRound`) through a remote host configuration. **No authentication required.**

The remote host configuration is already set up in your Pi configuration. Pi will connect to it automatically.

### Other Authentication Options (Not Needed for Your Setup)

**Option 1: Pi CLI (For OAuth-backed providers)**

```bash
pi /login  # Only needed for providers like Anthropic, OpenAI, etc.
```

**Option 2: Environment Variables (For API-key providers)**

```bash
# Only needed if using cloud providers
ANTHROPIC_API_KEY=sk-...
OPENAI_API_KEY=sk-...
GEMINI_API_KEY=AI...
```

## Workflow Compatibility

All workflows in `.archon/workflows/` are now configured to:

- Use `provider: pi` (or inherit from default)
- Use Pi-compatible model names
- Work with any Pi backend

**Removed Claude-specific fields:**

- `effort` - Not supported by Pi
- `thinking` - Not supported by Pi
- `allowed_tools` - Use Pi's tool restrictions instead
- `mcp` - Use Pi's MCP configuration
- `skills` - Use Pi's skills system

## Available Models

Check what models are available by running:

```bash
pi /models
```

Or check the Pi documentation for the full list of supported backends.

## Troubleshooting

### Model Not Found

```
Error: Model "xyz" is not compatible with provider "pi"
```

**Solution:** Use the correct format: `<provider-id>/<model-id>`

Example: `anthropic/claude-sonnet-4-5` not just `claude-sonnet-4-5`

### Authentication Failed

```bash
Error: Authentication required for provider "anthropic"
```

**Solution:** Only applies to cloud providers. For your local model setup, ensure:

1. Remote host is configured correctly in Pi config
2. Remote host is accessible and running

### Tool Not Supported

Some Pi backends have limited tool support. Check the model's capabilities:

- Full tool support: Claude, GPT-4
- Limited tool support: Smaller models
- No tool support: Some open-source models

## Migration from Claude/Codex

If you previously used Claude or Codex:

1. **Update `.env`**: Set `DEFAULT_AI_ASSISTANT=pi`
2. **Update workflows**: Change `provider: claude` to `provider: pi`
3. **Update models**: Change `model: sonnet` to `model: anthropic/claude-sonnet-4-5`
4. **Remove Claude-specific fields**: `effort`, `thinking`, `allowed_tools`, etc.

## Benefits of Pi

- **Unified interface**: One adapter for 20+ LLM backends
- **Model flexibility**: Switch models without changing workflow logic
- **Cost optimization**: Use cheaper models for simple tasks
- **Best-in-class**: Choose the best model for each task
- **Future-proof**: New models added automatically

## Example: Multi-Model Workflow

```yaml
name: multi-model-workflow
provider: pi

nodes:
  - id: classify
    prompt: |
      Classify this task: {{input}}
    model: openai/gpt-4.1-mini # Fast classification

  - id: implement
    depends_on: [classify]
    prompt: |
      Implement based on classification: {{classify.output}}
    model: anthropic/claude-sonnet-4-5 # Capable implementation

  - id: review
    depends_on: [implement]
    prompt: |
      Review the implementation
    model: google/gemini-2.5-pro # Different perspective
```

## Support

- **Pi Documentation**: See `@mariozechner/pi-coding-agent` docs
- **Model Support**: Check Pi's model compatibility matrix
- **Extensions**: Pi supports extensions, skills, and custom providers
