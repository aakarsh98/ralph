# Intelligent Model Selection

This document describes how Ralph selects the optimal model for each task.

## The Problem

Using one model for all tasks is wasteful:
- **Simple tasks** (rename, config change) don't need Claude Opus
- **Complex tasks** (architecture, debugging) need more reasoning power
- **Token costs** vary 8x between cheapest and most expensive models

## The Solution: Task-Based Model Selection

Ralph analyzes each story and selects the most efficient model.

## Model Tiers (Cost → Quality)

| Tier | Models | Multiplier | Best For |
|------|--------|------------|----------|
| **1 - Budget** | Gemini Flash, Droid Core (GLM-4.7) | 0.2-0.25× | Boilerplate, simple edits |
| **2 - Efficient** | Haiku 4.5, GPT-5.1, GPT-5.1-Codex, GPT-5.1-Codex-Max | 0.4-0.5× | Most implementation tasks |
| **3 - Balanced** | GPT-5.2, GPT-5.2-Codex, Gemini 3 Pro | 0.7-0.8× | Moderate-complex tasks |
| **4 - Premium** | Sonnet 4.5 | 1.2× | Feature development |
| **5 - Maximum** | Opus 4.5 | 2.0× | Critical/complex work |

### All 11 Factory Models

| Model | ID | Cost | Reasoning Options |
|-------|-----|------|-------------------|
| Gemini 3 Flash | `gemini-3-flash-preview` | 0.2× | minimal/low/medium/high |
| Droid Core | `glm-4.7` | 0.25× | none only |
| Haiku 4.5 | `claude-haiku-4-5-20251001` | 0.4× | off/low/medium/high |
| GPT-5.1 | `gpt-5.1` | 0.5× | none/low/medium/high |
| GPT-5.1-Codex | `gpt-5.1-codex` | 0.5× | low/medium/high |
| GPT-5.1-Codex-Max | `gpt-5.1-codex-max` | 0.5× | low/medium/high/**extra-high** |
| GPT-5.2 | `gpt-5.2` | 0.7× | low/medium/high |
| GPT-5.2-Codex | `gpt-5.2-codex` | 0.7× | low/medium/high |
| Gemini 3 Pro | `gemini-3-pro-preview` | 0.8× | low/high |
| Sonnet 4.5 | `claude-sonnet-4-5-20250929` | 1.2× | off/low/medium/high |
| Opus 4.5 | `claude-opus-4-5-20251101` | 2.0× | off/low/medium/high |

## Task Complexity Classification

### Trivial (Tier 1)
- Rename variables
- Update config values
- Add imports
- Fix typos
- **Indicators**: 1 file, 1-2 acceptance criteria, keyword: "simple", "rename", "config"

### Simple (Tier 1-2)
- Add single method
- Fix simple bug
- Add validation
- **Indicators**: 1-2 files, 3-4 acceptance criteria, straightforward logic

### Moderate (Tier 2-3)
- Add feature
- Refactor module
- Write tests
- **Indicators**: 3-5 files, 5-6 acceptance criteria, requires context understanding

### Complex (Tier 3-4)
- Architecture changes
- Debug complex issues
- Multi-system changes
- **Indicators**: 5+ files, 7+ acceptance criteria, keywords: "debug", "architecture"

### Critical (Tier 4-5)
- Security architecture
- Performance optimization
- Novel problem solving
- **Indicators**: Keywords: "critical", "security", "design", ambiguous requirements

## Selection Algorithm

```python
def select_model(story):
    complexity = assess_complexity(story)
    
    if complexity == "trivial":
        return "gemini-3-flash-preview"  # 0.2×, fast
    elif complexity == "simple":
        return "claude-haiku-4-5-20251001"  # 0.4×, reliable
    elif complexity == "moderate":
        return "gpt-5.1-codex"  # 0.5×, good for code
    elif complexity == "complex":
        return "claude-sonnet-4-5-20250929"  # 1.2×, balanced
    elif complexity == "critical":
        return "claude-opus-4-5-20251101"  # 2.0×, maximum quality

def assess_complexity(story):
    score = 0
    
    # Check acceptance criteria count
    criteria_count = len(story.acceptanceCriteria)
    if criteria_count <= 2: score += 0
    elif criteria_count <= 4: score += 1
    elif criteria_count <= 6: score += 2
    else: score += 3
    
    # Check for complexity keywords
    text = story.title + story.description
    if any(kw in text.lower() for kw in ["rename", "config", "typo"]):
        score -= 1
    if any(kw in text.lower() for kw in ["debug", "architecture", "security"]):
        score += 2
    if any(kw in text.lower() for kw in ["critical", "complex", "design"]):
        score += 3
    
    # Map score to complexity
    if score <= 0: return "trivial"
    elif score <= 1: return "simple"
    elif score <= 2: return "moderate"
    elif score <= 3: return "complex"
    else: return "critical"
```

## Reasoning Effort by Complexity

| Complexity | Reasoning |
|------------|-----------|
| Trivial | none |
| Simple | low |
| Moderate | medium |
| Complex | high |
| Critical | extra-high (if available) |

## Cost Savings Example

**PRD with 10 stories:**

| Stories | Fixed Model (Opus) | Dynamic Selection | Savings |
|---------|-------------------|-------------------|---------|
| 3 trivial | 3 × 2.0× = 6.0× | 3 × 0.2× = 0.6× | 90% |
| 4 simple | 4 × 2.0× = 8.0× | 4 × 0.4× = 1.6× | 80% |
| 2 moderate | 2 × 2.0× = 4.0× | 2 × 0.5× = 1.0× | 75% |
| 1 complex | 1 × 2.0× = 2.0× | 1 × 1.2× = 1.2× | 40% |
| **Total** | **20.0×** | **4.4×** | **78%** |

## Override Options

Force a specific model in prd.json:

```json
{
  "id": "US-001",
  "title": "Critical security fix",
  "model": "claude-opus-4-5-20251101",
  "reasoning": "high"
}
```

Or set a project-wide minimum:

```json
{
  "project": "MyApp",
  "minModel": "gpt-5.1-codex",
  "maxModel": "claude-sonnet-4-5-20250929"
}
```

## Integration with Ralph

The `ralph.sh` script:
1. Reads the current story
2. Assesses complexity
3. Selects optimal model
4. Passes `--model` flag to `droid exec`
5. Logs model used in metrics.json
