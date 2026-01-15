# Droid Ralph

Droid implementation of Ralph for [Factory's Droid CLI](https://docs.factory.ai).

## Key Features

- **Two Modes**: Normal (fast) and Strict (verified)
- **Pattern Learning**: AGENTS.md captures project intelligence across iterations
- **Evidence-Based**: Strict mode verifies each criterion with commands
- **Metrics**: Track performance, tokens, and success rate

## Quick Start

### Initialize a New Project
```bash
chmod +x tools/init-project.sh
./tools/init-project.sh /path/to/project strict
```

### Or Copy Files Manually
```bash
cd strict  # or normal
cp ralph.sh prompt.md /path/to/project/
cp ../templates/AGENTS.md.template /path/to/project/AGENTS.md
```

### Run Ralph
```bash
cd /path/to/project
./ralph.sh 10
```

## Two Modes

| Mode | Speed | Verification | Pattern Learning |
|------|-------|--------------|------------------|
| **Normal** | Fast | Quality checks only | Light |
| **Strict** | Slower | VERIFY: commands | Mandatory |

## AGENTS.md - Project Intelligence

The key to smarter iterations. AGENTS.md stores:

```markdown
## Code Patterns
- Naming conventions
- Import patterns
- Error handling style

## Known Gotchas
- Things that will trip you up

## Architecture Decisions
- Why things are the way they are

## Recent Learnings
- Discoveries from each iteration
```

### Why AGENTS.md Matters

1. **Faster iterations** - AI doesn't rediscover patterns
2. **Fewer mistakes** - Gotchas are documented
3. **Consistent code** - Patterns are followed
4. **Compounding knowledge** - Each iteration learns from previous

## Verification Prefixes (Strict Mode)

| Prefix | Action |
|--------|--------|
| `VERIFY:` | Run command, must exit 0 |
| `VERIFY_FILE_EXISTS:` | File must exist |
| `VERIFY_FILE_CONTAINS:` | Pattern must be in file |
| `VERIFY_BUILD:` | Build must succeed |
| `VERIFY_TEST:` | Test must pass |
| `VERIFY_OUTPUT:` | Output must contain pattern |

## Tools

### Initialize Project
```bash
./tools/init-project.sh /path/to/project [normal|strict]
```

Creates: ralph.sh, prompt.md, AGENTS.md, progress.txt, prd.json template

### Consolidate Patterns
```bash
./tools/consolidate-patterns.sh /path/to/project
```

Extracts patterns from progress.txt for AGENTS.md

### Compare Modes
```bash
./compare.sh
```

Runs both modes and generates comparison report

## File Structure

```
droid/
├── normal/                 # FAST MODE
│   ├── ralph.sh           
│   ├── prompt.md          # Light pattern learning
│   └── prd.json           
│
├── strict/                 # VERIFIED MODE
│   ├── ralph.sh           
│   ├── prompt.md          # Mandatory AGENTS.md + verification
│   └── prd.json           # With VERIFY: prefixes
│
├── templates/
│   └── AGENTS.md.template # Structured pattern template
│
├── tools/
│   ├── init-project.sh    # Initialize new projects
│   └── consolidate-patterns.sh  # Extract patterns
│
└── compare.sh              # Mode comparison
```

## Workflow

```
1. Initialize project with AGENTS.md
2. Fill in known patterns/gotchas
3. Create prd.json with stories
4. Run ralph.sh
5. Each iteration:
   - Reads AGENTS.md patterns
   - Implements story
   - Verifies (strict mode)
   - Updates AGENTS.md with learnings
   - Commits and continues
6. Periodically consolidate patterns
```

## When to Use Each Mode

| Scenario | Mode |
|----------|------|
| Prototyping | Normal |
| Production code | Strict |
| Large/complex projects | Strict |
| Simple tasks | Normal |
| Critical features | Strict |
| Learning the codebase | Strict (builds AGENTS.md) |

## Intelligent Model Selection (NEW)

Ralph now automatically selects the most efficient model based on task complexity:

| Complexity | Model | Cost | Use Case |
|------------|-------|------|----------|
| **Trivial** | Gemini Flash | 0.2× | Config, rename, typos |
| **Simple** | Haiku 4.5 | 0.4× | Add method, simple bug |
| **Moderate** | GPT-5.1 Codex | 0.5× | Features, refactoring |
| **Complex** | Sonnet 4.5 | 1.2× | Multi-file, architecture |
| **Critical** | Opus 4.5 | 2.0× | Security, complex debug |

**Potential savings: 60-80% on token costs** compared to using one model for all tasks.

### Use Smart Mode
```bash
cd strict
chmod +x ralph-smart.sh
./ralph-smart.sh 10
```

See `models/MODELS.json` for full model registry.

## Prerequisites

- [Droid CLI](https://docs.factory.ai) installed
- `jq` for JSON processing
- `git` repository initialized
