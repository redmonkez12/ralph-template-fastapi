# Claude Code Project Instructions

This project uses the Ralph autonomous agent loop. Process rules live in `AGENT.md` and `PROMPT.md`.
Technical skills live in `.claude/skills/` and provide deep framework-specific guidance.

**When skills and AGENT.md conflict, AGENT.md wins.**

## Skill Routing

Read the relevant skill before implementing changes in that area:

| Working on | Read skill |
|---|---|
| FastAPI routes, Pydantic models, async DB | `.claude/skills/fastapi-expert/` |
| Next.js pages, components, App Router | `.claude/skills/nextjs-developer/` |
| TypeScript types, generics, patterns | `.claude/skills/typescript-pro/` |
| Python code, stdlib, async, packaging | `.claude/skills/python-pro/` |
| Writing or fixing tests | `.claude/skills/test-master/` |
| Debugging failures or errors | `.claude/skills/debugging-wizard/` |
| Self-reviewing before commit | `.claude/skills/code-reviewer/` |

Each skill directory contains a `SKILL.md` with patterns and constraints.
Tier 1 skills (fastapi-expert, nextjs-developer, typescript-pro, python-pro, test-master) also have a `references/` directory with deep-dive docs on specific topics.

## How to Use Skills

1. Identify which area your task touches
2. Read the matching `SKILL.md` for patterns and constraints
3. Consult `references/` files when you need detail on a specific topic
4. Apply skill guidance within the bounds of AGENT.md rules

## Skill Source

Skills are curated from [Jeffallan/claude-skills](https://github.com/Jeffallan/claude-skills) (MIT licensed).
