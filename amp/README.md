# Ralph for Amp

This directory contains the original Ralph implementation for [Amp CLI](https://ampcode.com).

## Prerequisites

- [Amp CLI](https://ampcode.com) installed and authenticated
- `jq` installed (`brew install jq` on macOS)
- A git repository for your project

## Setup

Copy these files into your project:

```bash
mkdir -p scripts/ralph
cp ralph.sh scripts/ralph/
cp prompt.md scripts/ralph/
cp prd.json.example scripts/ralph/prd.json
chmod +x scripts/ralph/ralph.sh
```

Optionally install the skills globally:

```bash
cp -r skills/prd ~/.config/amp/skills/
cp -r skills/ralph ~/.config/amp/skills/
```

## Usage

### 1. Create a PRD

```
Load the prd skill and create a PRD for [your feature]
```

### 2. Convert to prd.json

```
Load the ralph skill and convert tasks/prd-feature.md to prd.json
```

### 3. Run Ralph

```bash
./ralph.sh [max_iterations]
```

## Files

| File | Purpose |
|------|---------|
| `ralph.sh` | Main bash loop that spawns Amp instances |
| `prompt.md` | Instructions for each Amp iteration |
| `prd.json.example` | Example PRD format |
| `skills/prd/` | PRD generator skill |
| `skills/ralph/` | PRD-to-JSON converter skill |

## How It Works

1. `ralph.sh` reads `prd.json` and spawns a fresh Amp instance
2. Amp picks the highest priority story with `passes: false`
3. Amp implements the story, runs quality checks, commits
4. Amp marks the story as `passes: true` in prd.json
5. Loop repeats until all stories complete

Memory persists via:
- `prd.json` (task status)
- `progress.txt` (learnings)
- Git history (code changes)
