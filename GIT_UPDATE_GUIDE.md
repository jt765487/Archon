# Git Update Guide for Pi Provider Fixes

This guide explains how to check for upstream changes and re-apply your Pi provider fixes when needed.

## Your Branch

**Branch Name:** `pi-fixes`

**Main Commit:** `d51f75bb` - "feat: Add Pi provider support with custom model configuration"

## Quick Check for Updates

```bash
# Check if dev has new commits
git fetch origin
git log dev..pi-fixes --oneline    # Your changes not in dev
git log pi-fixes..origin/dev --oneline  # Changes in dev not in your branch
```

## Sync Your Branch with Latest Dev

### Option 1: Merge (Recommended for most cases)

```bash
git checkout pi-fixes
git merge origin/dev
```

### Option 2: Rebase (Cleaner history)

```bash
git checkout pi-fixes
git rebase origin/dev
```

## Check if Your Changes Are Still Applied

After syncing, verify your Pi fixes are still in place:

```bash
# Check if your main commit is still in the branch
git log --oneline | grep "Pi provider support"

# Verify key files still have your changes
git diff dev..pi-fixes --stat
```

## What to Do If Changes Conflict

If you see conflicts after merging/rebasing:

1. **Check what changed in dev:**

   ```bash
   git log pi-fixes..origin/dev --oneline
   git show <commit-hash>  # Review specific changes
   ```

2. **Resolve conflicts manually:**
   - Check if the conflict is in source code (`packages/`) or workflows (`.archon/workflows/`)
   - For workflows: Ensure `provider: pi` and `model: vllm/Intel/Qwen3.5-122B-A10B-int4-AutoRound` are preserved
   - For source code: Keep your custom model support changes

3. **Complete the merge/rebase:**
   ```bash
   git add <resolved-files>
   git commit  # For merge
   git rebase --continue  # For rebase
   ```

## Key Files to Monitor

Your Pi provider changes are in these files:

| File                                                   | Purpose                             | Check If...                  |
| ------------------------------------------------------ | ----------------------------------- | ---------------------------- |
| `packages/providers/src/community/pi/provider.ts`      | Custom model support, optional auth | Pi provider stops working    |
| `packages/core/src/services/title-generator.ts`        | Load default Pi model from config   | Title generation fails       |
| `packages/core/src/orchestrator/orchestrator-agent.ts` | Chunk limits (1000/5000)            | Responses get truncated      |
| `packages/providers/src/community/pi/event-bridge.ts`  | Error logging                       | Debugging needed             |
| `.archon/workflows/defaults/*.yaml`                    | All workflows use `provider: pi`    | Workflows use wrong provider |

## Common Scenarios

### Scenario 1: Dev has new commits, no conflicts

```bash
git checkout pi-fixes
git merge origin/dev
# ✅ Continue working normally
```

### Scenario 2: Dev has new commits with conflicts

```bash
git checkout pi-fixes
git merge origin/dev
# Resolve conflicts
git add <files>
git commit
# ✅ Continue working normally
```

### Scenario 3: Your changes were already merged upstream

```bash
git fetch origin
git log dev..pi-fixes --oneline
# If your commit appears in dev, you can delete pi-fixes
git branch -d pi-fixes
```

### Scenario 4: Pi provider stopped working after update

```bash
# Check if your changes are still there
git diff HEAD~3 -- packages/providers/src/community/pi/provider.ts

# If changes are missing, re-apply manually:
# 1. Check out a fresh copy
# 2. Cherry-pick your commit
git cherry-pick d51f75bb
```

## Testing After Update

Always test after syncing:

```bash
# Test 1: Verify Pi provider loads
bun run cli chat "hello"

# Test 2: Verify custom model works
bun run cli workflow run pi-chat --no-worktree "Test"

# Test 3: Check for errors
bun run cli chat "test" 2>&1 | grep -i "error\|warn"
```

## Expected Output

After a successful update:

```
✅ No conflicts during merge/rebase
✅ `bun run cli chat` works without errors
✅ Custom model loads from ~/.pi/agent/models.json
✅ No "Pi provider requires a model" errors
✅ No authentication errors for vllm provider
```

## Troubleshooting

| Issue                          | Solution                                                                                        |
| ------------------------------ | ----------------------------------------------------------------------------------------------- |
| "Pi provider requires a model" | Check `packages/providers/src/community/pi/provider.ts` - ModelRegistry.create() should be used |
| Custom model not found         | Check `~/.pi/agent/models.json` exists and has vllm config                                      |
| Title generation fails         | Check `packages/core/src/services/title-generator.ts` - loadDefaultPiModel() should work        |
| Workflow uses wrong provider   | Check `.archon/workflows/defaults/archon-assist.yaml` - should have `provider: pi`              |
| Responses truncated            | Check `packages/core/src/orchestrator/orchestrator-agent.ts` - MAX*BATCH*\* should be 1000/5000 |

## Branch Management

```bash
# List all branches
git branch -a

# Switch to pi-fixes
git checkout pi-fixes

# Switch to dev
git checkout dev

# Delete pi-fixes (if merged upstream)
git branch -d pi-fixes
```

## Backup Your Changes

If you're concerned about losing your changes:

```bash
# Create a backup branch
git checkout pi-fixes
git checkout -b pi-fixes-backup-$(date +%Y%m%d)

# Or export a patch
git format-patch dev..pi-fixes
```

---

**Last Updated:** 2026-04-21
**Current Commit:** `d14d24ab` (merge of dev into pi-fixes)
