# Local Model Setup (Pi via Remote Host)

## Your Configuration

**Model**: `vllm/Intel/Qwen3.5-122B-A10B-int4-AutoRound`  
**Provider**: `pi`  
**Authentication**: **Not required** (local model via remote host)

## How It Works

```
Archon → Pi Provider → Remote Host → Local Model (Qwen3.5-122B)
```

- Archon sends prompts to the Pi provider
- Pi connects to your configured remote host
- Remote host runs the local model
- No API keys or OAuth needed

## Configuration Files

### Archon Config (`~/.archon/config.yaml`)

```yaml
defaultAssistant: pi

assistants:
  pi:
    model: vllm/Intel/Qwen3.5-122B-A10B-int4-AutoRound

worktree:
  baseBranch: dev

docs:
  path: packages/docs-web/src/content/docs
```

### Environment (`.env`)

```bash
DEFAULT_AI_ASSISTANT=pi
# No API keys needed for local model setup
```

## Testing Your Setup

### 1. Verify Pi Can Reach Remote Host

```bash
# Test Pi connectivity (command depends on your remote host setup)
# This will vary based on how your remote host is configured
```

### 2. Test Archon Workflow

```bash
# List workflows (should show 28 workflows)
bun run cli workflow list

# Run a simple workflow
bun run cli workflow run assist "What is the current date?"
```

### 3. Check Workflow Loading

```bash
# Verify all workflows load without errors
bun run cli validate workflows
```

## Troubleshooting

### Connection Issues

**Error**: `Failed to connect to remote host`

**Solutions:**

1. Verify remote host is running
2. Check remote host URL/configuration in Pi config
3. Verify network connectivity to remote host
4. Check firewall settings

### Model Not Found

**Error**: `Model "vllm/Intel/Qwen3.5-122B-A10B-int4-AutoRound" not found`

**Solutions:**

1. Verify the model name matches exactly what's configured on remote host
2. Check remote host's model list/availability
3. Update the model name in `~/.archon/config.yaml` if needed

### Timeout Errors

**Error**: `Request timeout`

**Solutions:**

1. Model may be slow (122B is large)
2. Increase timeout in workflow configuration if needed
3. Check remote host resource availability

## Using Different Models

If you want to switch to a different model on your remote host:

### Option 1: Global Change

Edit `~/.archon/config.yaml`:

```yaml
assistants:
  pi:
    model: vllm/<your-model-name>
```

### Option 2: Per-Workflow

Add to workflow YAML:

```yaml
provider: pi
model: vllm/different-model-name
```

## Remote Host Configuration

Your remote host configuration is managed separately from Archon. Common setups include:

### vLLM Server

```bash
# Example vLLM launch command
vllm serve Intel/Qwen3.5-122B-A10B-int4-AutoRound \
  --port 8000 \
  --host 0.0.0.0
```

### Ollama

```bash
# Example Ollama serve
ollama serve
```

### Other Options

- **Text Generation WebUI**
- **LocalAI**
- **Custom API endpoint**

Refer to your remote host documentation for specific configuration.

## Performance Considerations

### Model Size: 122B Parameters

**Expected Performance:**

- **Speed**: Slower than smaller models (seconds to minutes per response)
- **Quality**: High-quality outputs, good for complex tasks
- **Resource Usage**: Significant RAM/VRAM requirements

**Optimization Tips:**

1. Use smaller models for simple tasks
2. Batch requests when possible
3. Consider model quantization (already using int4)
4. Ensure adequate system resources

## Cost

**Your Setup: $0**

- Local model = no API costs
- Only electricity and hardware costs
- Unlimited usage

## Comparison with Cloud Models

| Aspect          | Your Local Model        | Cloud (Anthropic/OpenAI) |
| --------------- | ----------------------- | ------------------------ |
| **Cost**        | Free (hardware only)    | Pay per token            |
| **Privacy**     | Complete (runs locally) | Data sent to cloud       |
| **Speed**       | Depends on hardware     | Generally fast           |
| **Reliability** | Your control            | Service dependent        |
| **Setup**       | One-time configuration  | API key only             |

## Security

**Advantages:**

- ✅ No data leaves your network (if remote host is local)
- ✅ No API keys to manage or leak
- ✅ Complete control over model and data

**Considerations:**

- Ensure remote host is properly secured
- Use HTTPS if accessing remotely
- Implement authentication at remote host level if needed

## Next Steps

1. **Test with a simple workflow**:

   ```bash
   bun run cli workflow run assist "Explain what Archon does"
   ```

2. **Monitor performance**:
   - Check response times
   - Monitor resource usage
   - Adjust model if needed

3. **Optimize for your use case**:
   - Consider different models for different tasks
   - Configure appropriate timeouts
   - Set up monitoring/logging

---

**Status**: ✅ Your Pi setup with local model is configured and ready to use.
