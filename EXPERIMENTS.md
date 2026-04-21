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

### Run 2 — _pending_

**Routing model**: TBD
**Implementation model**: TBD
**Outcome**: —

---

## What to Try Next

- [ ] Use `dgx-spark` for implementation nodes, `gss-api/claude-haiku-4-5` only for routing
- [ ] Try `gss-api/deepseek-v3` for implementation
- [ ] Try `gss-api/claude-sonnet-4-6` as full end-to-end (baseline for comparison)
- [ ] Fix Qwen routing truncation (stop token / generation config issue)
- [ ] Try a harder issue (multiple files, more complex logic)
