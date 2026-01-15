<coding_guidelines>
# Ralph Agent Instructions

## Overview

Ralph is an autonomous AI agent loop that runs an AI coding assistant repeatedly until all PRD items are complete. Each iteration is a fresh instance with clean context.

## Implementations

- `amp/` - Original implementation for Amp CLI
- `droid/` - Implementation for Factory's Droid CLI

## Commands

```bash
# Droid version
cd droid && ./droid-ralph.sh [max_iterations]

# Amp version
cd amp && ./ralph.sh [max_iterations]

# Flowchart dev server (documentation)
cd flowchart && npm run dev
```

## Key Files

### Droid Implementation (`droid/`)
- `droid-ralph.sh` - Bash loop using `droid exec`
- `droid-prompt.md` - Instructions for each iteration
- `.factory/droids/` - Custom Droids for interactive mode
- `.factory/commands/` - Slash commands (`/prd`, `/ralph`)

### Amp Implementation (`amp/`)
- `ralph.sh` - Bash loop using `amp`
- `prompt.md` - Instructions for each iteration
- `skills/` - Amp skills for PRD generation

### Shared
- `prd.json` - User stories with `passes` status
- `progress.txt` - Append-only learnings
- `AGENTS.md` - Agent instructions (this file)

## Patterns

- Each iteration spawns a fresh AI instance with clean context
- Memory persists via git history, `progress.txt`, and `prd.json`
- Stories should be small enough to complete in one context window
- Always update AGENTS.md with discovered patterns for future iterations
- Quality checks (typecheck, lint, test) must pass before committing
</coding_guidelines>
