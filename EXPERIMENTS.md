# Local Model Experiments with Archon + Pi Provider

## What This Is

A personal test harness for evaluating local and remote LLMs as AI coding agents via
[Archon](https://github.com/coleam00/Archon) and the
[Pi coding agent](https://github.com/badlogic/pi-mono).

The experiment: can a locally-hosted model on a DGX Spark (or a remote model via a
government API) produce production-quality Python code via an agentic workflow — with
zero human intervention between "here's an issue" and "here's a PR"?

---

## Setup

### Hardware

- **DGX Spark** (`192.168.0.41`) running vllm on port 8000
- **This Mac** running the Archon server + Pi provider

### Model under test (default)

```
dgx-spark/Intel/Qwen3.5-122B-A10B-int4-AutoRound
```

Configured in `~/.pi/agent/models.json` under provider key `dgx-spark`.

### Fallback / routing model

```
gss-api/claude-haiku-4-5
```

Available via `~/.pi/agent/models.json` → `gss-api` (keychain credential:
`security find-generic-password -a devex-litellm -s jarvis-litellm -w`).

### Available models (from `~/.pi/agent/models.json`)

| Provider key    | Base URL                                      | Notable models                                                    |
| --------------- | --------------------------------------------- | ----------------------------------------------------------------- |
| `dgx-spark`     | `http://192.168.0.41:8000/v1`                 | `Intel/Qwen3.5-122B-A10B-int4-AutoRound`                          |
| `gss-api`       | `https://api.chat.hosting.gss.gov.uk/v1`      | `claude-haiku-4-5`, `claude-sonnet-4-6`, `gpt-4.1`, `deepseek-v3` |
| `devex-litellm` | `https://devex-litellm.hosting.gss.gov.uk/v1` | `gpt-4.1`, `claude-sonnet-4-6`, `o3-mini`                         |

---

## The Test Task

**Repo**: `jt765487/test-app` (registered in Archon as a codebase)

**Issue #2**: Add a `greet` module to `src/test_app/` with:

- `GreetInput` — Pydantic v2 model, `name: str` (non-empty), `title: str` (optional, default `""`)
- `greet(data: GreetInput) -> str` — pure function, returns `"Hello, {title} {name}!"` or `"Hello, {name}!"`
- Tests: example-based + at least one Hypothesis property test
- `make validate` passes (format + lint + type-check + coverage ≥ 80%)

**Quality gates** (all automated via `make validate`):

- `ruff format` — formatting
- `ruff check` — linting (McCabe ≤ 10, type annotations enforced, no f-strings in logging)
- `ty check` — type checking
- `pytest --cov` — tests with branch coverage ≥ 80%

### Resetting the test-app between runs

```bash
cd /Users/john51246/GIT/TEST_APP

# Remove the generated code and tests
git checkout main
git branch -D fix-issue-2 2>/dev/null || true

# Delete any remote branches from prior runs
gh pr close <N> --delete-branch 2>/dev/null || true

# Confirm clean state
git log --oneline -3
git status
```

The issue stays open on GitHub — just close/delete the PR each time.

---

## How to Run an Experiment

### 1. Set the model under test

Edit `~/.archon/config.yaml`:

```yaml
defaultAssistant: pi
assistants:
  pi:
    model: dgx-spark/Intel/Qwen3.5-122B-A10B-int4-AutoRound # ← change this
    enableExtensions: false
```

### 2. Start the server

```bash
cd /Users/john51246/GIT/archon
bun run dev:server
```

### 3. Open the web UI

http://localhost:5173 — start a new conversation scoped to `jt765487/test-app`

### 4. Prompt

```
implement issue 2
```

### 5. Watch it run

The workflow `test-app-fix-issue` (in `.archon/workflows/`) runs 8 nodes:
`fetch-issue` → `investigate` → `format` → `lint` → `type-check` → `test` → `ai-review` → `create-pr`

If it fails on a bash node (missing tool etc.), resume with:

```bash
bun run cli workflow resume <run-id>
```

Get the run ID from:

```bash
bun run cli workflow status
```

### 6. Score the result

See scoring rubric below.

---

## Workflow Used

**File**: `.archon/workflows/test-app-fix-issue.yaml` (in `jt765487/test-app` repo)

The workflow runs entirely in an isolated git worktree under
`~/.archon/workspaces/jt765487/test-app/worktrees/`.

---

## Known Environment Issues (one-time fixes, already done)

| Issue                                                 | Fix                                          |
| ----------------------------------------------------- | -------------------------------------------- |
| `ruff` not in PATH                                    | `uv tool install ruff`                       |
| `ty` not in PATH                                      | `uv tool install ty`                         |
| `~/.local/bin` not in server PATH                     | Added to `PATH=` in `.env`                   |
| DGX Spark model ref was `vllm/...`                    | Fixed to `dgx-spark/...` in all config files |
| Existing conversations had `ai_assistant_type=claude` | Migrated in SQLite                           |

---

## Results

### Run 1 — `gss-api/claude-haiku-4-5` — 2026-04-21

**Routing model**: `gss-api/claude-haiku-4-5`
**Implementation model**: `gss-api/claude-haiku-4-5`
**Outcome**: ✅ PR created — [#4](https://github.com/jt765487/test-app/pull/4)

**Notes**:

- First attempted with `dgx-spark/Intel/Qwen3.5-122B-A10B-int4-AutoRound` for routing
- Qwen consistently truncated `/invoke-workflow` with no workflow name — workflow never fired
- Switched routing to Haiku which reliably outputs the full command
- DGX Spark model was **not used** in any successful node
- Two bash tooling failures mid-run (`ruff` and `ty` not installed) — fixed and resumed

**Code quality**:

- Matched spec exactly — correct Pydantic v2 validator, both greeting formats, pure function
- 6 example tests + 3 Hypothesis property tests (spec required 1 minimum)
- All quality gates passed first time once tooling was installed

**Scoring** (0–5 per dimension):

| Dimension       | Score | Notes                                             |
| --------------- | ----- | ------------------------------------------------- |
| Spec compliance | 5/5   | Exact match on all acceptance criteria            |
| Code quality    | 5/5   | Clean, minimal, no unnecessary complexity         |
| Test quality    | 5/5   | Good branch coverage, meaningful property tests   |
| Independence    | 3/5   | Two manual interventions (tooling + DB migration) |
| Model used      | ❌    | DGX Spark not actually used                       |

---

### Run 2 — `gss-api/claude-sonnet-4-6` E2E — 2026-04-22

**Routing model**: `gss-api/claude-sonnet-4-6`
**Implementation model**: `gss-api/claude-sonnet-4-6`
**Workflow**: `test-app-run-2-sonnet`
**Outcome**: ✅ PR created — [#5](https://github.com/jt765487/test-app/pull/5)

**Notes**:

- Workflow failed mid-run on `type-check` — worktree `.venv` missing dev deps (`pytest`, `hypothesis`)
- Fixed by adding `install` node (`make install`) before `investigate` in all three experiment workflows
- Resumed from the `install` node; all subsequent nodes passed first time
- `ai-review` emitted two `⚠️ Tool read failed` and two `⚠️ Tool bash failed` warnings but recovered and completed — one loop iteration, declared "Implementation is complete and correct"
- `create-pr` correctly staged only the three relevant files, left workflow YAMLs and `.archon/config.yaml` unstaged

**Code quality**:

- Clean, minimal implementation — 31 lines of source, 79 lines of tests
- Pydantic v2 `field_validator` with `@classmethod`, correct empty-name guard
- 6 example-based tests + 3 Hypothesis property tests covering all branches
- All quality gates passed

**Scoring** (0–5 per dimension):

| Dimension       | Score | Notes                                                       |
| --------------- | ----- | ----------------------------------------------------------- |
| Spec compliance | 5/5   | Exact match on all acceptance criteria                      |
| Code quality    | 5/5   | Clean, minimal, idiomatic Pydantic v2                       |
| Test quality    | 5/5   | Full branch coverage, meaningful property tests             |
| Independence    | 4/5   | One infra intervention (missing `install` node — now fixed) |
| Model used      | ✅    | `gss-api/claude-sonnet-4-6` used for all AI nodes           |

```bash
bun run cli workflow run test-app-run-2-sonnet \
  --branch experiment/run-2-sonnet-e2e \
  --cwd /Users/john51246/GIT/TEST_APP \
  "2"
```

---

### Run 3 — `gss-api/claude-haiku-4-5` router / `gss-api/kimi-k2.5` implementer — 2026-04-22

**Routing model**: `gss-api/claude-haiku-4-5`
**Implementation model**: `gss-api/kimi-k2.5`
**Workflow**: `test-app-run-3-haiku-kimi`
**Outcome**: ✅ PR created — [#6](https://github.com/jt765487/test-app/pull/6)

**Notes**:

- Uncovered a provider-resolution bug: `inferProviderFromModel` checked only `builtIn` providers; Codex's `isModelCompatible` accepted any non-Claude model string (including Pi refs like `gss-api/kimi-k2.5`), so nodes with `model:` but no `provider:` were silently routed to Codex despite `provider: pi` at the workflow level. Fixed in `dag-executor.ts:resolveNodeProviderAndModel` — community-style model refs (containing `/`) now skip inference and inherit `workflowProvider` directly.
- Also required `DEFAULT_AI_ASSISTANT=pi` in `~/.archon/.env` (CLI strips the repo `.env`; global env file is the correct location).
- `create-pr` used wrong issue number (`Closes #1` instead of `Closes #2`) — likely Kimi didn't read the fetch-issue output carefully.
- Correctly deleted `tests/test_placeholder.py` (Sonnet left it untouched).

**Code quality**:

- Clean, correct implementation — 38 lines of source, proper Pydantic v2 `field_validator`, full Google-style docstrings
- 4 example tests + 1 Hypothesis property test (fewer property tests than Sonnet's 3)
- All quality gates passed

**Scoring** (0–5 per dimension):

| Dimension       | Score | Notes                                                                |
| --------------- | ----- | -------------------------------------------------------------------- |
| Spec compliance | 4/5   | Correct implementation; PR referenced wrong issue number (#1 not #2) |
| Code quality    | 5/5   | Clean, minimal, idiomatic — better docstrings than Sonnet            |
| Test quality    | 4/5   | Good example coverage; only 1 Hypothesis test vs Sonnet's 3          |
| Independence    | 4/5   | Provider routing bug required infra fix; otherwise fully autonomous  |
| Model used      | ✅    | `gss-api/kimi-k2.5` used for all AI nodes                            |

```bash
bun run cli workflow run test-app-run-3-haiku-kimi \
  --branch experiment/run-3-haiku-kimi \
  --cwd /Users/john51246/GIT/TEST_APP \
  "2"
```

---

### Run 4 — `gss-api/kimi-k2.5` router / `dgx-spark` Qwen implementer — 2026-04-22

**Routing model**: `gss-api/kimi-k2.5`
**Implementation model**: `dgx-spark/Intel/Qwen3.5-122B-A10B-int4-AutoRound`
**Workflow**: `test-app-run-4-kimi-qwen`
**Outcome**: ✅ PR created — [#7](https://github.com/jt765487/test-app/pull/7)

**Notes**:

- DGX Spark Qwen used for all AI nodes (`investigate`, `ai-review`, `create-pr`) — the original goal achieved
- Kimi K2.5 routed correctly; no truncation issues (unlike Qwen as router in Run 1)
- PR incorrectly staged the three experiment workflow YAMLs (`.archon/workflows/test-app-run-*.yaml`) — Qwen didn't scope the `git add` to only implementation files
- PR refs `Fixes #1` instead of `Fixes #2` — same wrong-issue-number issue as Kimi (Run 3); possibly a pattern with non-Sonnet models
- Added `Field(min_length=1)` constraint in addition to the `field_validator` — belt-and-braces validation (slightly redundant but not wrong)
- Whitespace-only name rejection (`v.strip()`) goes beyond spec — spec only requires non-empty, not non-whitespace

**Code quality**:

- 51 lines of source — most thorough docstrings of all three runs (full Args/Returns/Raises)
- 122 lines of tests — most comprehensive: grouped into `TestGreetInput`, `TestGreetFunction`, `TestGreetHypothesis` classes
- 4 Hypothesis property tests (more than Sonnet's 3): return type, starts with "Hello,", ends with "!", name in result
- Extra test: whitespace-only name rejection (beyond spec but sensible)
- Complex title test (`"Prof. John Smith"`) — good edge case

**Scoring** (0–5 per dimension):

| Dimension       | Score | Notes                                                                |
| --------------- | ----- | -------------------------------------------------------------------- |
| Spec compliance | 4/5   | Correct implementation; wrong issue # in PR; staged unrelated files  |
| Code quality    | 5/5   | Best docstrings of all three runs; well-structured                   |
| Test quality    | 5/5   | Most thorough — 4 Hypothesis properties, class-grouped, extra cases  |
| Independence    | 4/5   | Provider routing infra fix (shared with Run 3); PR staging error     |
| Model used      | ✅    | `dgx-spark/Intel/Qwen3.5-122B-A10B-int4-AutoRound` used for AI nodes |

```bash
bun run cli workflow run test-app-run-4-kimi-qwen \
  --branch experiment/run-4-kimi-qwen \
  --cwd /Users/john51246/GIT/TEST_APP \
  "2"
```

---

## Pre-Run Reset Checklist

Run before each experiment (substitute the PR number from the previous run):

```bash
# 1. Close the previous run's PR and delete its remote branch
gh pr close <N> --delete-branch --repo jt765487/test-app 2>/dev/null || true

# 2. Clean up Archon worktrees for closed/merged branches
cd /Users/john51246/GIT/archon
bun run cli isolation cleanup --merged --include-closed

# 3. Reset test-app local branches
cd /Users/john51246/GIT/TEST_APP
git checkout main && git pull origin main

# 4. Confirm clean state
git log --oneline -3
git status
gh pr list --repo jt765487/test-app   # should be empty
```

---

## What to Try Next

- [ ] Try a harder issue (multiple files, more complex logic)
- [ ] Fix Qwen routing truncation (stop token / generation config issue) to enable Qwen E2E
- [ ] Try `gss-api/deepseek-v3` for implementation
