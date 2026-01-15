# Ralph

![Ralph](ralph.webp)

Ralph is an autonomous AI agent loop that implements PRD items one at a time until all tasks are complete. Each iteration spawns a fresh AI instance with clean context, with **intelligent model selection** to optimize cost and quality.

Based on [Geoffrey Huntley's Ralph pattern](https://ghuntley.com/ralph/).

## Documentation

| Document | Description |
|----------|-------------|
| [**PRD.md**](./PRD.md) | Full product requirements document |
| [**QUICKSTART.md**](./QUICKSTART.md) | Step-by-step setup guide |
| [**AGENTS.md**](./AGENTS.md) | Agent instructions |

## Key Features

- **Autonomous Loop**: Runs until all PRD stories complete
- **Intelligent Model Selection**: Chooses optimal model per task (60-80% cost savings)
- **Pattern Learning**: Accumulates project knowledge in AGENTS.md
- **Skills Library**: Reusable skills triggered by task keywords
- **Verification Modes**: Normal (trust-based) and Strict (evidence-based)

## Quick Start

```bash
# Clone Ralph
git clone https://github.com/aakarsh-nadella-c4/ralph.git

# Copy to your project
cp ralph/droid/strict/ralph-smart.sh /path/to/your/project/
cp ralph/droid/strict/prompt.md /path/to/your/project/

# Create prd.json in your project (see QUICKSTART.md)

# Run Ralph
cd /path/to/your/project
chmod +x ralph-smart.sh
./ralph-smart.sh 10
```

See [QUICKSTART.md](./QUICKSTART.md) for detailed instructions.

## Intelligent Model Selection

Ralph automatically selects the most efficient model based on research from SWE-bench, Vellum, Anthropic, and OpenAI:

| Task Type | Model | Cost | Why |
|-----------|-------|------|-----|
| Simple (config, rename) | Gemini Flash | 0.2× | 80% of tasks can use smaller models |
| Code generation | GPT-5.1-Codex | 0.5× | Fast, creative solutions |
| Refactoring | Claude Sonnet 4.5 | 1.2× | Cleaner, idiomatic code |
| Complex debugging | Claude Opus 4.5 | 2.0× | Best contextual understanding |
| Architecture | Claude Opus 4.5 | 2.0× | Handles ambiguity well |

See [droid/models/MODEL-RESEARCH.md](./droid/models/MODEL-RESEARCH.md) for full research citations.

## How It Works

```
┌─────────────────────────────────────────────────────────┐
│  RALPH SMART MODE                                       │
├─────────────────────────────────────────────────────────┤
│  FOR each iteration:                                    │
│    1. Read prd.json → find next incomplete story        │
│    2. Assess complexity (trivial → critical)            │
│    3. Detect task type (debug, refactor, new code)      │
│    4. Select optimal model based on research            │
│    5. Load patterns from AGENTS.md                      │
│    6. Load relevant skills from skills-library          │
│    7. Execute story with selected model                 │
│    8. Verify acceptance criteria                        │
│    9. Update prd.json, log to progress.txt              │
│   10. Repeat until all stories complete                 │
└─────────────────────────────────────────────────────────┘
```

## Project Structure

```
ralph/
├── PRD.md                  # Product requirements document
├── QUICKSTART.md           # Step-by-step setup guide
├── AGENTS.md               # Agent instructions
│
├── droid/                  # Factory Droid implementation
│   ├── normal/            # Trust-based mode
│   ├── strict/            # Verification mode
│   │   └── ralph-smart.sh # With intelligent model selection
│   ├── models/            # Model selection system
│   │   ├── MODELS.json    # Registry of 11 models
│   │   └── MODEL-RESEARCH.md  # Research citations
│   └── .factory/          # Interactive droids
│
├── amp/                    # Amp CLI implementation
│   ├── ralph.sh           # Main loop script
│   └── prompt.md          # AI instructions
│
├── skills-library/         # Shared skills
│   ├── REGISTRY.json      # Skill triggers
│   ├── core/              # Always-active skills
│   ├── testing/           # TDD, verification
│   ├── debugging/         # Systematic debugging
│   └── planning/          # Task breakdown
│
└── flowchart/              # Interactive visualization
```

## Implementations

| Mode | Script | Description |
|------|--------|-------------|
| **Smart** | `droid/strict/ralph-smart.sh` | Intelligent model selection (recommended) |
| **Strict** | `droid/strict/droid-ralph.sh` | Verification required |
| **Normal** | `droid/normal/droid-ralph.sh` | Trust-based, faster |
| **Amp** | `amp/ralph.sh` | For Amp CLI users |

## Cost Savings Example

For a PRD with 10 stories of mixed complexity:

| Approach | Token Cost | Savings |
|----------|------------|---------|
| Fixed Opus (2.0×) | 20× baseline | - |
| Smart Selection | 4-6× baseline | **70-80%** |

## Flowchart

[![Ralph Flowchart](ralph-flowchart.png)](https://snarktank.github.io/ralph/)

**[View Interactive Flowchart](https://snarktank.github.io/ralph/)**

## References

- [Geoffrey Huntley's Ralph article](https://ghuntley.com/ralph/)
- [Factory Droid documentation](https://docs.factory.ai)
- [Amp documentation](https://ampcode.com/manual)
- [SWE-bench Leaderboard](https://swebench.com)
- [OpenAI GPT-5.1 Prompting Guide](https://cookbook.openai.com/examples/gpt-5/gpt-5-1_prompting_guide)
