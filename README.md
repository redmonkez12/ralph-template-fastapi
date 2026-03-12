# Ralph Loop Template

An autonomous coding agent loop powered by Claude Code and Linear. The agent picks up tasks from your Linear project, implements them one at a time, validates its work, commits, pushes, and updates Linear — then loops back for the next task.

## Prerequisites

- [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code) installed and authenticated
- A [Linear](https://linear.app) account with an API key
- A Linear project with issues in the backlog
- Git repository for your actual project (this template lives alongside it or is integrated into it)

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
   source .env
   while :; do cat PROMPT.md | claude --dangerously-skip-permissions -p - ; done
   ```

## Customizing AGENT.md

AGENT.md contains two sections marked with `<!-- CUSTOMIZE -->` comments:

### Repository Context

Replace the placeholder with your project's tech stack and goals. This tells the agent what it's working on.

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

```markdown
### TypeScript
- Use strict TypeScript — no `any` unless unavoidable.
- Prefer interfaces over type aliases for object shapes.
- Use named exports over default exports.
- Keep Express middleware thin.
```

Everything else in AGENT.md is generic loop infrastructure — you shouldn't need to change it unless you want to customize the agent's behavior.

## How It Works

Each loop iteration:

1. **`scripts/fetch_linear_task.py`** queries Linear for the next task (resumes in-progress work first, then picks from backlog)
2. The task is written to **`state/current-task.md`**
3. Claude reads **AGENT.md** + **PROMPT.md** + the task context
4. Claude implements the task, runs validation, commits, and pushes
5. **`scripts/update_linear_issue.py`** updates the Linear issue status and adds a comment
6. The loop restarts

The agent outputs one of: `DONE`, `BLOCKED`, `FAILED`, or `NEEDS_SPLIT`.

## File Reference

| File | Purpose |
|------|---------|
| `AGENT.md` | Repository rules, coding standards, and agent behavior constraints |
| `PROMPT.md` | Per-iteration execution prompt — the agent's "instructions" each loop |
| `RALPH.md` | Quick-reference run commands |
| `scripts/common_linear.py` | Shared Linear GraphQL client |
| `scripts/fetch_linear_task.py` | Picks the next task from Linear and writes `state/current-task.md` |
| `scripts/update_linear_issue.py` | Updates Linear issue state and adds comments |
| `specs/` | Specification documents referenced by tasks |
| `state/` | Runtime state (gitignored) — `current-task.md`, `progress.md`, `blockers.md` |
| `.env` | Linear API credentials (gitignored) |

## Running

See `RALPH.md` for the run commands, or use:

```bash
# Interactive mode (you see each step, can intervene)
source .env
while :; do cat PROMPT.md | claude --dangerously-skip-permissions ; done

# Autonomous mode (fully hands-off)
source .env
while :; do cat PROMPT.md | claude --dangerously-skip-permissions -p - ; done
```

## Tips

- Keep Linear issues small and well-described — the agent works best with clear, single-task issues
- Use the `blocked` label in Linear to skip issues the agent can't handle
- Parent issues with sub-issues are automatically skipped (the agent picks leaf tasks)
- The agent auto-unblocks issues when their blocking issues are completed
- Add detailed specs to `specs/` for complex tasks — reference them in the Linear issue description
