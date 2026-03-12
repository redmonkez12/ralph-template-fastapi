## Purpose

This repository is operated by an autonomous coding agent working in a Ralph-style loop.
The agent must implement exactly one task per loop iteration, validate its work, and leave the repository in a clean, reviewable state.

The source of truth for task selection is Linear.
The runtime context for the current iteration is provided in `state/current-task.md`.

---

## Core Rule: One Task Per Loop

You must work on exactly one task per loop.

Allowed:
- implement one Linear issue
- update only files required for that issue
- add or adjust tests required for that issue
- update local progress/state files for that issue

Forbidden:
- starting a second issue in the same loop
- opportunistic refactors unrelated to the current issue
- fixing unrelated bugs "while here"
- making broad architecture changes unless explicitly required by the task

If the current task expands beyond a reasonable single-task scope, stop and return `NEEDS_SPLIT`.

---

## Required Reading Order

Before making any changes, read in this order:

1. `state/current-task.md`
2. `PROMPT.md`
3. Relevant files from `specs/` referenced by `state/current-task.md`
4. Relevant source files only
5. Relevant existing tests only

Do not read or scan the whole repository unless necessary.

---

## Repository Context

<!-- CUSTOMIZE: Describe your project's tech stack and goals.
     Replace this entire comment block with your project's details.

Example:

This project is a Python backend built with:

- Python 3.14
- uv
- FastAPI
- PostgreSQL
- modular monolith architecture

Primary goals:
- ship clean MVP features fast
- keep architecture simple
- preserve future extensibility
- keep operational complexity low
-->

---

## Architecture Principles

Follow these principles when implementing changes:

1. Prefer a modular monolith over microservices.
2. Keep domain boundaries clean.
3. Prefer explicit code over clever abstractions.
4. Avoid speculative generalization.
5. Reuse existing patterns before introducing new ones.
6. Keep public API behavior consistent.
7. Preserve backward compatibility unless the task explicitly allows breaking changes.
8. Keep persistence, domain logic, and API wiring reasonably separated.
9. Add only the minimal schema and code required for the current task.

---

## Allowed Change Scope

You may change only what is necessary to complete the current issue, including:

- application code
- tests
- migrations
- schemas / DTOs
- configuration strictly required for the task
- docs directly related to the changed behavior
- state/progress files required by the loop

Avoid unrelated file churn.

---

## Coding Standards

### General
- Write clear, production-oriented code.
- Prefer small, readable functions.
- Prefer explicit names.
- Avoid dead code and commented-out code.
- Do not leave TODOs unless the current task explicitly requires them.

### Language-Specific

<!-- CUSTOMIZE: Add coding standards specific to your project's language(s) and frameworks.
     Replace this entire comment block with your standards.

Example for Python:

- Use modern Python 3.14 features when they improve clarity.
- Follow existing style in the repository.
- Prefer type hints on public/internal interfaces where appropriate.
- Keep Pydantic / schema definitions clean and explicit.
- Keep FastAPI route handlers thin when possible.
- Put business logic outside route handlers when non-trivial.
- NEVER remove parentheses from multi-exception except clauses.

Example for TypeScript:

- Use strict TypeScript — no `any` unless unavoidable.
- Prefer interfaces over type aliases for object shapes.
- Use named exports over default exports.
-->

### Data / Persistence
- Keep migrations deterministic and reviewable.
- Do not modify old migrations unless explicitly required.
- Add new migrations for schema changes.
- Avoid destructive schema changes unless explicitly requested.

### API
- Follow existing response conventions.
- Keep pagination/filtering conventions consistent.
- Preserve auth and permission checks.
- Validate input strictly.
- Return appropriate HTTP status codes.

---

## Testing Standards

Every task must include validation proportional to the change.

Before editing:
- verify whether relevant tests already exist
- verify whether similar functionality already exists

After implementation:
- run relevant tests for changed behavior
- run lint/type checks if configured for the repo
- fix failing checks within the scope of the issue

Prefer:
- targeted tests first
- broader test runs second if needed

Do not claim success without actually running validation commands.

If tests cannot be run, state that explicitly in the final output.

---

## Definition of Done

A task is DONE only if all of the following are true:

1. The requested behavior is implemented.
2. Acceptance criteria in `state/current-task.md` are satisfied.
3. Relevant tests were added or updated when appropriate.
4. Relevant validation was run.
5. No unrelated work was included.
6. Progress/state files were updated.
7. Changes are committed and pushed to the remote branch.
8. The change is ready for review.

If any of the above is not true, do not mark the task as DONE.

---

## When to Return BLOCKED

Return `BLOCKED` instead of coding if any of the following is true:

- the task depends on missing prerequisite work
- acceptance criteria are contradictory or incomplete
- the required behavior is unclear from task/spec context
- the task requires secrets, credentials, infrastructure, or external access not available
- the task would require a major out-of-scope design decision
- the relevant module/spec does not exist and the task cannot be safely inferred

When blocked:
- do not improvise large product decisions
- do not start another issue
- explain the blocker clearly and concretely

---

## When to Return NEEDS_SPLIT

Return `NEEDS_SPLIT` if the task cannot reasonably be completed as a single iteration because it requires multiple substantial pieces of work, for example:

- schema + API + admin tooling + search indexing + background jobs all at once
- multiple domain modules with large cross-cutting impact
- a broad refactor disguised as one issue

When returning `NEEDS_SPLIT`, suggest 2-5 smaller implementation tasks.

---

## Search and Discovery Rules

Before implementing:
- search for existing modules, endpoints, services, helpers, or tests related to the task
- do not assume functionality is missing without verifying

Prefer extending existing patterns over introducing parallel ones.

---

## Refactoring Rules

Refactor only when required to complete the current issue safely.

Allowed:
- small local cleanup required to support the task
- extracting a helper if it clearly reduces duplication in touched code
- minor restructuring to keep module boundaries clean

Forbidden:
- repository-wide cleanup
- renames unrelated to the task
- replacing core patterns without explicit requirement
- broad architectural rewrites

---

## Migrations and Seed Data

If schema changes are needed:
- add a new migration
- keep it minimal
- ensure application code and tests match the new schema

If seed/dev fixtures must be updated:
- change only what is necessary for local/dev/test correctness

---

## Security and Moderation Expectations

Always preserve baseline security expectations:

- do not accidentally expose private data
- preserve auth checks
- preserve permission checks
- validate user-controlled input
- avoid unsafe file handling
- avoid insecure defaults

---

## Performance and Operational Guardrails

Do not introduce obviously expensive patterns without need.

Avoid:
- unnecessary N+1 queries
- loading large datasets into memory without reason
- blocking operations in request paths when avoidable
- unbounded loops over database records in API handlers

Keep observability and operability in mind, but do not add heavy infra unless the task requires it.

---

## Git and Commit Rules (Mandatory)

Make concise, reviewable changes. **You MUST commit and push before finishing the loop.** Uncommitted work is equivalent to not doing the task.

### Required steps after validation passes:

1. Create or switch to the branch from the Linear issue's `gitBranchName`
2. Stage only the files you changed for this task (no `git add -A` or `git add .`)
3. Commit with a conventional scoped message
4. Push to remote with `git push -u origin <branch-name>`
5. Verify the push succeeded

Commit message style:
- `feat(projects): add project follow endpoint`
- `fix(auth): enforce recruiter-only organization access`
- `test(listings): cover compensation type validation`

Do not create multiple unrelated commits in one loop unless explicitly requested.

If pre-commit hooks fail, fix the issues, re-stage, and create a NEW commit (never amend).

---

## Files the Agent Must Update

For each loop, update as appropriate:

- `state/progress.md`
- `state/current-task.md` only if the workflow expects status notes there
- `state/blockers.md` only when blocked

Do not rewrite historical progress unnecessarily.

---

## Final Output Contract

At the end of the loop, output exactly one of:

- `DONE`
- `BLOCKED`
- `FAILED`
- `NEEDS_SPLIT`

And include this structure:

STATUS: <DONE|BLOCKED|FAILED|NEEDS_SPLIT>
ISSUE: <issue-id>
SUMMARY: <short summary>
FILES_CHANGED:
- <file>
- <file>
TESTS_RUN:
- <command/result>
ACCEPTANCE_CRITERIA:
- <met/not met>
COMMIT_MESSAGE: <message or N/A>
LINEAR_COMMENT:
<short ready-to-paste update>

If validation was not run, say so explicitly.

---

## Absolute Forbidden Actions

Never do any of the following unless explicitly instructed by the current task:

- work on more than one issue
- edit secrets or production credentials
- delete large parts of the codebase
- rewrite unrelated modules
- invent product requirements not supported by the task/spec
- silently skip tests
- claim completion without validation
- mark a blocked task as done
- close out missing dependencies by assumption

---

## Agent Mindset

Be conservative in scope, precise in execution, and explicit about uncertainty.

Priority order:
1. correctness
2. task scope discipline
3. validation
4. code cleanliness
5. speed

A small correct change is better than a large ambitious change.
