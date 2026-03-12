# Ralph Loop Template

An autonomous coding agent loop powered by Claude Code and Linear. The agent picks up tasks from your Linear project, implements them one at a time, validates its work, commits, pushes, and updates Linear — then loops back for the next task.

## Prerequisites

- [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code) installed and authenticated
- A [Linear](https://linear.app) account with an API key
- A Linear project with issues in the backlog
- `jq` installed (`brew install jq` on macOS)
- Python 3.10+

## Quick Start

1. **Clone this template** into your project (or copy the files):
   ```bash
   git clone <this-repo-url> ralph-loop
   cd ralph-loop
   ```

2. **Configure environment variables**:
   ```bash
   cp .env.example .env
   # Edit .env with your Linear API key and project name
   ```

3. **Customize AGENT.md** — fill in the two placeholder sections:
   - **Repository Context**: Describe your tech stack, language, frameworks, and goals
   - **Language-Specific Coding Standards**: Add rules for your language/framework

4. **Add specs** (optional): Drop specification documents into `specs/` for tasks that reference them.

5. **Prepare your Linear backlog** — before running the loop, audit your Linear issues to make sure they're agent-ready. Paste the following prompt into ChatGPT / Claude and replace the project name with yours:

   <details>
   <summary>Backlog audit prompt</summary>

   ```
   You are acting as a senior engineering manager preparing a Linear project
   backlog for autonomous development using a Ralph-style agent loop.

   Project name: <YOUR PROJECT NAME>

   Prepare the backlog so that tasks can be safely executed by an autonomous
   coding agent. The agent can only work on tasks that are:
     - clearly scoped
     - implementable in one iteration
     - technically well specified
     - not dependent on missing work

   Your job: Audit all issues in the Linear project and transform them into
   agent-ready tasks. For each issue you must determine:
     1. Is the task executable by an autonomous coding agent?
     2. Is the scope small enough for a single implementation loop?
     3. Are acceptance criteria present and clear?
     4. Are dependencies clearly defined?
     5. Is the issue an implementation task or something else?

   If a task is too large, split it into multiple smaller tasks.

   For each issue produce the following analysis:

   Issue: <issue-id>
   Title: <title>

   Classification:
     - implementation / research / architecture / product / manual / infra

   Execution readiness:
     - READY / NEEDS_SPLIT / NEEDS_SPEC / BLOCKED / MANUAL

   Required labels: ready, needs-split, needs-spec, blocked, analysis, manual, agent-safe
   Dependencies: List any prerequisite tasks.
   Improved description: Rewrite the task description to be clear for an autonomous coding agent.
   Acceptance criteria: Write concrete, testable acceptance criteria.
   Scope notes: Explain what is explicitly OUT OF SCOPE.

   If the issue must be split, propose 2–5 new tasks.

   Your goal is to produce a backlog where tasks labeled ready + agent-safe
   can be safely executed by an autonomous coding agent. Avoid vague
   descriptions. Prefer small implementation tasks over large ones.
   ```

   </details>

6. **Run the loop** — choose your agent:
   ```bash
   # Using Claude Code
   ./afk-ralph-claude.sh 5

   # Using Codex
   ./afk-ralph-codex.sh 5
   ```

## Customizing AGENT.md

AGENT.md contains two sections marked with `<!-- CUSTOMIZE -->` comments:

### Repository Context

Replace the placeholder with your project's tech stack and goals. This tells the agent what it's working on.

**Python example:**
```markdown
## Repository Context

This project is a Python backend built with:

- Python 3.14
- uv
- FastAPI
- PostgreSQL
- modular monolith architecture

Primary goals:
- ship clean MVP features fast
- keep architecture simple
```

**TypeScript example:**
```markdown
## Repository Context

This project is a Node.js API built with:

- TypeScript 5.x
- Express
- PostgreSQL + Prisma
- monorepo with turborepo

Primary goals:
- ship MVP features for launch
- keep the API surface small and consistent
```

### Language-Specific Coding Standards

Replace the placeholder with coding standards for your language(s) and frameworks.

**Python example:**
```markdown
### Python
- Use modern Python 3.14 features when they improve clarity.
- Follow existing style in the repository.
- Prefer type hints on public/internal interfaces where appropriate.
- Keep Pydantic / schema definitions clean and explicit.
- Keep FastAPI route handlers thin when possible.
- Put business logic outside route handlers when non-trivial.
```

**TypeScript example:**
```markdown
### TypeScript
- Use strict TypeScript — no `any` unless unavoidable.
- Prefer interfaces over type aliases for object shapes.
- Use named exports over default exports.
```

Everything else in AGENT.md is generic loop infrastructure — you shouldn't need to change it unless you want to customize the agent's behavior.

## How It Works

Each loop iteration (managed by `afk-ralph-claude.sh` or `afk-ralph-codex.sh`):

1. **`scripts/fetch_linear_task.py`** queries Linear for the next task (resumes in-progress work first, then picks from backlog)
2. The task is written to **`state/current-task.md`**
3. The issue is marked **In Progress** in Linear
4. Claude reads **AGENT.md** + **PROMPT.md** + the task context
5. Claude implements the task, runs validation, commits, and pushes
6. **`scripts/update_linear_issue.py`** updates the Linear issue status and adds a comment
7. The loop restarts for the next iteration

The agent outputs one of: `DONE`, `BLOCKED`, `FAILED`, or `NEEDS_SPLIT`.

## File Reference

| File | Purpose |
|------|---------|
| `afk-ralph-claude.sh` | Main loop using Claude Code as the coding agent |
| `afk-ralph-codex.sh` | Main loop using Codex as the coding agent |
| `AGENT.md` | Repository rules, coding standards, and agent behavior constraints |
| `PROMPT.md` | Per-iteration execution prompt — the agent's "instructions" each loop |
| `scripts/common_linear.py` | Shared Linear GraphQL client |
| `scripts/fetch_linear_task.py` | Picks the next task from Linear and writes `state/current-task.md` |
| `scripts/update_linear_issue.py` | Updates Linear issue state and adds comments |
| `specs/` | Specification documents referenced by tasks |
| `state/` | Runtime state (gitignored) — `current-task.md`, `progress.md`, `blockers.md` |
| `.env` | Linear API credentials (gitignored) |

## Running

### Claude Code

```bash
# Run 5 iterations
./afk-ralph-claude.sh 5

# Override model and effort
./afk-ralph-claude.sh 10 --model opus --effort high

# Defaults come from ~/.claude/settings.json (model + effortLevel)
```

### Codex

```bash
# Run 5 iterations
./afk-ralph-codex.sh 5

# Pass extra Codex flags via environment variables
CODEX_ARGS="--full-auto -m gpt-5.4" ./afk-ralph-codex.sh 5

# Environment variables:
#   CODEX_CMD           Codex binary (default: codex)
#   CODEX_ARGS          Extra Codex flags (e.g. --full-auto -m gpt-5.4)
#   CODEX_SUBCOMMAND    Agent subcommand (default: exec)
```

## Tips

- Keep Linear issues small and well-described — the agent works best with clear, single-task issues
- Use the `blocked` label in Linear to skip issues the agent can't handle
- Parent issues with sub-issues are automatically skipped (the agent picks leaf tasks)
- The agent auto-unblocks issues when their blocking issues are completed
- Add detailed specs to `specs/` for complex tasks — reference them in the Linear issue description
- A lock file (`state/ralph.lock`) prevents concurrent runs
- Logs are saved to `logs/ralph-<timestamp>.log` for each iteration
