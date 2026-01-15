# Ralph - Autonomous AI Agent Loop

## Product Requirements Document (PRD)

**Version**: 2.0  
**Last Updated**: January 2026  
**Status**: Active Development

---

## 1. Executive Summary

Ralph is an autonomous AI agent loop that runs an AI coding assistant (Droid or Amp) repeatedly until all tasks in a PRD are complete. Each iteration spawns a fresh AI instance with clean context, enabling sustained autonomous work across multiple coding sessions.

### Key Innovation

Ralph introduces **intelligent model selection** - automatically choosing the most efficient AI model for each task based on complexity and type, potentially saving **60-80% on token costs** compared to using a single premium model for all tasks.

---

## 2. Problem Statement

### Current Pain Points

1. **Token Waste**: Using Claude Opus (2.0×) for simple config changes wastes tokens
2. **Context Loss**: AI loses context between sessions, repeating mistakes
3. **Manual Selection**: Developers must manually choose models for each task
4. **No Learning**: AI doesn't learn from project-specific patterns

### Solution

Ralph provides:
- **Autonomous Loop**: Runs until all PRD items complete
- **Smart Model Selection**: Chooses optimal model per task complexity
- **Pattern Learning**: Accumulates knowledge in AGENTS.md
- **Verification System**: Ensures quality before marking tasks done

---

## 3. Target Users

| User Type | Use Case |
|-----------|----------|
| **Solo Developers** | Automate feature development overnight |
| **Small Teams** | Batch process multiple stories |
| **Agencies** | Run parallel projects cost-effectively |
| **Enterprise** | Standardize AI-assisted development |

---

## 4. Core Features

### 4.1 Autonomous Execution Loop

```
┌─────────────────────────────────────────────────────────┐
│                    RALPH LOOP                           │
├─────────────────────────────────────────────────────────┤
│  1. Read prd.json → Find next incomplete story          │
│  2. Assess complexity → Select optimal model            │
│  3. Load patterns from AGENTS.md                        │
│  4. Execute story with selected model                   │
│  5. Verify acceptance criteria                          │
│  6. Update prd.json (passes: true/false)                │
│  7. Log learnings to progress.txt                       │
│  8. Repeat until all stories complete                   │
└─────────────────────────────────────────────────────────┘
```

### 4.2 Intelligent Model Selection

Based on extensive research (see `droid/models/MODEL-RESEARCH.md`):

| Task Complexity | Model | Cost | Research Source |
|-----------------|-------|------|-----------------|
| **Trivial** | Gemini 3 Flash | 0.2× | 80% of tasks can use smaller models |
| **Simple** | GPT-5.1-Codex | 0.5× | Fast code generation (GitHub) |
| **Moderate** | GPT-5.1-Codex | 0.5× | Good balance |
| **Complex** | Claude Sonnet 4.5 | 1.2× | 82% SWE-bench leader |
| **Critical** | Claude Opus 4.5 | 2.0× | Best debugging (Anthropic) |

**Task-Type Overrides**:
- Debugging → Claude Opus (superior context understanding)
- Refactoring → Claude Sonnet (cleaner code - SonarSource)
- Architecture → Claude Opus (handles ambiguity)

### 4.3 Pattern Learning System

Ralph learns from each project through:

1. **AGENTS.md**: Project-specific patterns, conventions, gotchas
2. **progress.txt**: Append-only log of learnings per iteration
3. **Skills Library**: Reusable skills triggered by task keywords

### 4.4 Skills Library

```
skills-library/
├── core/
│   ├── skill-selector.md      # Auto-selects relevant skills
│   └── pattern-learning.md    # AGENTS.md integration
├── testing/
│   ├── tdd.md                 # Test-Driven Development
│   └── verification.md        # Pre-completion checks
├── debugging/
│   └── systematic.md          # 4-phase root cause analysis
└── planning/
    ├── writing-plans.md       # Task breakdown
    └── executing-plans.md     # Plan execution
```

### 4.5 Verification Modes

| Mode | Description | Use Case |
|------|-------------|----------|
| **Normal** | Trust-based completion | Rapid prototyping |
| **Strict** | Evidence-based verification | Production code |
| **Compare** | Runs both, generates report | Evaluation |

---

## 5. Technical Architecture

### 5.1 Directory Structure

```
ralph/
├── amp/                        # Amp CLI implementation
│   ├── ralph.sh               # Main loop script
│   ├── prompt.md              # Iteration instructions
│   └── skills/                # Amp-specific skills
│
├── droid/                      # Factory Droid implementation
│   ├── normal/                # Trust-based mode
│   │   ├── droid-ralph.sh
│   │   └── prompt.md
│   ├── strict/                # Verification mode
│   │   ├── ralph-smart.sh     # With model selection
│   │   └── prompt.md
│   ├── models/                # Model selection system
│   │   ├── MODELS.json        # Registry (11 models)
│   │   ├── model-selector.md  # Quick reference
│   │   └── MODEL-RESEARCH.md  # Research sources
│   ├── templates/             # PRD templates
│   └── .factory/              # Interactive droids
│
├── skills-library/             # Shared skills
│   └── REGISTRY.json          # Skill triggers
│
└── flowchart/                  # Documentation site
```

### 5.2 Model Registry (11 Models)

| Model | ID | Multiplier | Best For |
|-------|-----|------------|----------|
| Gemini 3 Flash | `gemini-3-flash-preview` | 0.2× | High-volume, simple |
| Droid Core | `glm-4.7` | 0.25× | Bulk automation |
| Haiku 4.5 | `claude-haiku-4-5-20251001` | 0.4× | Routine tasks |
| GPT-5.1 | `gpt-5.1` | 0.5× | General purpose |
| GPT-5.1-Codex | `gpt-5.1-codex` | 0.5× | Code generation |
| GPT-5.1-Codex-Max | `gpt-5.1-codex-max` | 0.5× | Extra-high reasoning |
| GPT-5.2 | `gpt-5.2` | 0.7× | Abstract reasoning |
| GPT-5.2-Codex | `gpt-5.2-codex` | 0.7× | Complex code |
| Gemini 3 Pro | `gemini-3-pro-preview` | 0.8× | Research flows |
| Sonnet 4.5 | `claude-sonnet-4-5-20250929` | 1.2× | Daily driver |
| Opus 4.5 | `claude-opus-4-5-20251101` | 2.0× | Critical work |

### 5.3 Complexity Assessment Algorithm

```python
def assess_complexity(story):
    score = 0
    
    # Acceptance criteria count
    criteria = len(story.acceptanceCriteria)
    if criteria <= 2: score += 0
    elif criteria <= 4: score += 1
    elif criteria <= 6: score += 2
    else: score += 3
    
    # Keyword analysis
    text = story.title + story.description
    if matches(text, ["rename", "config", "typo"]): score -= 1
    if matches(text, ["debug", "architecture"]): score += 2
    if matches(text, ["critical", "security"]): score += 3
    
    # Map to complexity
    if score <= 0: return "trivial"
    elif score <= 1: return "simple"
    elif score <= 2: return "moderate"
    elif score <= 3: return "complex"
    else: return "critical"
```

---

## 6. User Stories

### 6.1 Basic Usage

```
US-001: Run Ralph on a project
As a developer
I want to run Ralph on my PRD
So that all stories are completed autonomously

Acceptance Criteria:
- Ralph reads prd.json and identifies incomplete stories
- Each story is processed in priority order
- Progress is logged to progress.txt
- Stories are marked passes:true when verified
```

### 6.2 Model Selection

```
US-002: Intelligent model selection
As a cost-conscious developer
I want Ralph to choose the cheapest effective model
So that I save tokens without sacrificing quality

Acceptance Criteria:
- Simple tasks use Gemini Flash (0.2×)
- Complex debugging uses Claude Opus
- Model choice is logged in metrics.json
- 60-80% cost savings vs fixed Opus usage
```

### 6.3 Pattern Learning

```
US-003: Learn project patterns
As a developer
I want Ralph to remember project-specific patterns
So that future iterations don't repeat mistakes

Acceptance Criteria:
- Ralph reads AGENTS.md before each iteration
- New learnings are appended to progress.txt
- Patterns are consolidated into AGENTS.md
- Gotchas and conventions are documented
```

---

## 7. Success Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| **Token Savings** | 60-80% | Compare smart vs fixed model |
| **Completion Rate** | >90% | Stories marked passes:true |
| **Iteration Efficiency** | <5 iterations/story | Average iterations needed |
| **Learning Retention** | 100% | Patterns available next session |

---

## 8. Roadmap

### Phase 1: Core Loop (Complete)
- [x] Basic Ralph loop for Amp
- [x] Droid implementation
- [x] Normal and Strict modes
- [x] Pattern learning via AGENTS.md

### Phase 2: Intelligence (Complete)
- [x] Skills library with triggers
- [x] Intelligent model selection
- [x] Research-backed recommendations
- [x] GPT-5.1 persistence patterns

### Phase 3: Optimization (In Progress)
- [ ] Windows batch scripts (.bat)
- [ ] Cost tracking dashboard
- [ ] Metaprompting for self-improvement
- [ ] Multi-project orchestration

### Phase 4: Enterprise (Planned)
- [ ] Team sharing of patterns
- [ ] Custom model fine-tuning
- [ ] CI/CD integration
- [ ] Analytics dashboard

---

## 9. Dependencies

### Required
- **Droid CLI** or **Amp CLI** installed
- **jq** for JSON processing
- **Git** for version control

### Optional
- **Node.js** for flowchart documentation
- **GitHub CLI** for automated PRs

---

## 10. Research References

Full citations available in `droid/models/MODEL-RESEARCH.md`:

1. SWE-bench Official Leaderboards (swebench.com)
2. Vellum LLM Leaderboard (vellum.ai)
3. Factory Documentation (docs.factory.ai)
4. OpenAI GPT-5.1 Prompting Guide (cookbook.openai.com)
5. Anthropic Claude Opus 4.5 Announcement
6. SonarSource Code Quality Analysis
7. eval.16x.engineer Reasoning Evaluation

---

## 11. Getting Started

See `QUICKSTART.md` for step-by-step instructions on using Ralph with your projects.

---

*This PRD is maintained alongside the codebase. Update when adding new features.*
