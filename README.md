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

5. **Run the loop**:
   ```bash
   ./afk-ralph.sh 5
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

Each loop iteration (managed by `afk-ralph.sh`):

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
| `afk-ralph.sh` | Main entry point — orchestrates the fetch/implement/update loop |
| `AGENT.md` | Repository rules, coding standards, and agent behavior constraints |
| `PROMPT.md` | Per-iteration execution prompt — the agent's "instructions" each loop |
| `scripts/common_linear.py` | Shared Linear GraphQL client |
| `scripts/fetch_linear_task.py` | Picks the next task from Linear and writes `state/current-task.md` |
| `scripts/update_linear_issue.py` | Updates Linear issue state and adds comments |
| `specs/` | Specification documents referenced by tasks |
| `state/` | Runtime state (gitignored) — `current-task.md`, `progress.md`, `blockers.md` |
| `.env` | Linear API credentials (gitignored) |

## Running

```bash
# Run 5 iterations
./afk-ralph.sh 5

# Override model and effort
./afk-ralph.sh 10 --model opus --effort high

# Defaults come from ~/.claude/settings.json (model + effortLevel)
```

## Tips

- Keep Linear issues small and well-described — the agent works best with clear, single-task issues
- Use the `blocked` label in Linear to skip issues the agent can't handle
- Parent issues with sub-issues are automatically skipped (the agent picks leaf tasks)
- The agent auto-unblocks issues when their blocking issues are completed
- Add detailed specs to `specs/` for complex tasks — reference them in the Linear issue description
- A lock file (`state/ralph.lock`) prevents concurrent runs
- Logs are saved to `logs/ralph-<timestamp>.log` for each iteration
