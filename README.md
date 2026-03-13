# Ralph Monorepo Template

A minimal Next.js + FastAPI monorepo template with the Ralph autonomous agent loop at the root. The application stack uses `bun` + `turbo` for workspace orchestration and `uv` for the FastAPI service.

## Monorepo Layout

```text
.
├── apps/
│   ├── api/        FastAPI app managed with uv
│   └── web/        Next.js App Router app managed with bun
├── scripts/        Ralph loop Linear helpers
├── specs/          Optional task specifications
├── state/          Runtime task state for the Ralph loop
├── AGENT.md        Repository-specific agent rules
└── PROMPT.md       Per-task execution prompt
```

## App Prerequisites

- Bun
- Python 3.12+
- [uv](https://docs.astral.sh/uv/)

## App Quick Start

1. Install JavaScript dependencies:
   ```bash
   bun install
   ```
2. Install Python dependencies:
   ```bash
   cd apps/api
   uv sync
   cd ../..
   ```
3. Create application env files:
   ```bash
   cp apps/web/.env.example apps/web/.env.local
   cp apps/api/.env.example apps/api/.env
   ```
4. Start both apps:
   ```bash
   bun run dev
   ```

The web app runs on `http://localhost:3000` and the API runs on `http://localhost:8000`.

## Monorepo Commands

```bash
bun run dev        # run web + api together through turbo
bun run build      # run all configured workspace builds
bun run lint       # lint web + api
bun run typecheck  # typecheck web + api
bun run test       # run backend tests
```

## Included App Behavior

- `apps/web` renders a simple dashboard page and checks API health from `NEXT_PUBLIC_API_BASE_URL`.
- `apps/api` exposes `GET /health` and allows the configured frontend origin through CORS.
- No database, auth, Docker, shared package, or generated API client is included in this starter.

## Ralph Loop Prerequisites

- [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code) installed and authenticated if you want to use the Claude runner
- Codex CLI installed if you want to use the Codex runner
- A [Linear](https://linear.app) account with an API key
- A Linear project with issues in the backlog
- `jq` installed for the Claude runner

## Ralph Loop Quick Start

1. Create the loop env file:
   ```bash
   cp .env.example .env
   ```
2. Set `LINEAR_API_KEY` and `LINEAR_PROJECT_NAME` in `.env`.
3. Add specs to `specs/` if your tasks reference longer design docs.
4. Run one of the loop runners:
   ```bash
   ./afk-ralph-claude.sh 5
   ./afk-ralph-codex.sh 5
   ```

## How the Ralph Loop Works

Each loop iteration:

1. `scripts/fetch_linear_task.py` selects one issue from Linear and writes `state/current-task.md`
2. `scripts/update_linear_issue.py` moves the issue to the active workflow state
3. The selected coding agent reads `AGENT.md`, `PROMPT.md`, and the task file, including the monorepo guidance for `apps/web` and `apps/api`
4. The agent implements the task, validates it, commits, pushes, and returns a structured status
5. The loop updates Linear with the outcome and repeats

The agent outputs one of: `DONE`, `BLOCKED`, `FAILED`, or `NEEDS_SPLIT`.

## Claude Skills

The `.claude/skills/` directory bundles curated technical skills from [Jeffallan/claude-skills](https://github.com/Jeffallan/claude-skills) (MIT). These provide deep framework-specific patterns for:

- **fastapi-expert** -- async endpoints, Pydantic V2, SQLAlchemy, auth, testing
- **nextjs-developer** -- App Router, server components, data fetching, deployment
- **typescript-pro** -- advanced types, generics, configuration, patterns
- **python-pro** -- async, type system, stdlib, packaging, testing
- **test-master** -- unit/integration/E2E testing, TDD
- **debugging-wizard** -- systematic debugging strategies
- **code-reviewer** -- structured code review

Skills are loaded via `CLAUDE.md` routing. To add more skills from the full collection, install the plugin: `/plugin marketplace add jeffallan/claude-skills`.

## File Reference

| File | Purpose |
|------|---------|
| `apps/web` | Next.js application |
| `apps/api` | FastAPI application |
| `afk-ralph-claude.sh` | Main loop using Claude Code |
| `afk-ralph-codex.sh` | Main loop using Codex |
| `AGENT.md` | Repo rules, standards, and agent behavior constraints |
| `PROMPT.md` | Per-iteration agent instructions |
| `scripts/common_linear.py` | Shared Linear GraphQL client |
| `scripts/fetch_linear_task.py` | Picks the next task from Linear |
| `scripts/update_linear_issue.py` | Updates issue state and comments |
| `specs/` | Optional specification docs |
| `state/` | Runtime state files used by the loop |

## Backlog Preparation Prompt

Before running the loop on a real project, audit your Linear backlog so issues are small, explicit, and executable by an autonomous coding agent.

```text
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
agent-ready tasks.
```

- Keep Linear issues small and well-described — the agent works best with clear, single-task issues
- Use the `blocked` label in Linear to skip issues the agent can't handle
- Parent issues with sub-issues are automatically skipped (the agent picks leaf tasks)
- The agent auto-unblocks issues when their blocking issues are completed
- Add detailed specs to `specs/` for complex tasks — reference them in the Linear issue description
- A lock file (`state/ralph.lock`) prevents concurrent runs
- Logs are saved to `logs/ralph-<timestamp>.log` for each iteration
