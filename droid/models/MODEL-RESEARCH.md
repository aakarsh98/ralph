# AI Model Selection Research

This document compiles research findings on which AI models perform best for different coding tasks, enabling intelligent model selection in Ralph.

**Sources**: OpenAI, Anthropic, Google, SWE-bench, Vellum AI, SonarSource, Factory Docs, academic papers, developer blogs (2025-2026)

---

## 1. Benchmark Leaderboards (January 2026)

### SWE-bench Verified (Real GitHub Bug Fixes)

| Rank | Model | Score | Notes |
|------|-------|-------|-------|
| 1 | Claude Sonnet 4.5 | **82.0%** | Best overall coding |
| 2 | Claude Opus 4.5 | 80.9% | First to break 80% barrier |
| 3 | GPT-5.2 | 80.0% | Strong reasoning |
| 4 | Gemini 3 Flash | 76.2% | Best budget option |
| 5 | GPT-5.1 | 76.3% | Good generalist |
| 6 | Gemini 3 Pro | 76.2% | Good for research flows |

*Source: swebench.com, vals.ai, vellum.ai (Jan 2026)*

### Math Reasoning (AIME 2025)

| Model | Score | Notes |
|-------|-------|-------|
| GPT-5.2 | **100%** | Perfect with tools |
| Gemini 3 Pro | 100% | Perfect with tools |
| Claude Opus 4.5 | ~94% | Strong but not perfect |

### Abstract Reasoning (ARC-AGI-2)

| Model | Score | Notes |
|-------|-------|-------|
| GPT-5.2 | **52.9%** | Best abstract reasoning |
| Gemini 3 Deep Think | 45.1% | Second best |
| Claude Opus 4.5 | 37.6% | Lower on abstract tasks |

**Key Finding**: Claude leads in coding, GPT-5.2 leads in reasoning/math.

---

## 2. Best Model by Task Type

### Debugging Existing Code

| Rank | Model | Why |
|------|-------|-----|
| 1 | **Claude Opus 4.5** | 80.9% SWE-bench, best at understanding context |
| 2 | Claude Sonnet 4.5 | 82% SWE-bench, faster than Opus |
| 3 | GPT-5.1-Codex-Max | Good with extra-high reasoning |

**Research says**: Claude excels at debugging due to:
- Superior contextual understanding
- Better at identifying root causes
- Handles ambiguity well without guidance
- Excellent at multi-system bugs

*Sources: Anthropic, Surge AI, cursor-ide.com, muneebdev.com*

### Writing New Code

| Rank | Model | Why |
|------|-------|-----|
| 1 | **GPT-5.1-Codex** | Fast, clean code generation |
| 2 | Claude Sonnet 4.5 | Best quality/speed balance |
| 3 | Gemini 3 Flash | Fastest for simple code |

**Research says**: GPT models excel at new code because:
- More creative/flexible in solutions
- Faster iteration cycles
- Good at boilerplate generation

*Sources: GitHub Copilot docs, designveloper.com, techpoint.africa*

### Complex Architecture & Design

| Rank | Model | Why |
|------|-------|-----|
| 1 | **Claude Opus 4.5** | Deepest reasoning, handles ambiguity |
| 2 | GPT-5.2 | Best abstract reasoning (52.9% ARC-AGI) |
| 3 | GPT-5.1-Codex-Max | Extra-high reasoning available |

**Research says**: Premium models needed because:
- Architecture requires multi-step reasoning
- Trade-off analysis needs deep context
- Ambiguous requirements need interpretation

*Sources: Factory docs, rdworldonline.com, vellum.ai*

### Simple Tasks (Config, Rename, Typos)

| Rank | Model | Why |
|------|-------|-----|
| 1 | **Gemini 3 Flash** | 0.2× cost, very fast |
| 2 | Droid Core (GLM-4.7) | 0.25× cost, good for bulk |
| 3 | Claude Haiku 4.5 | 0.4× cost, more reliable |

**Research says**: Using large models for simple tasks is wasteful:
- 80% of business tasks can use smaller models
- 90% cost reduction switching from GPT-4 to SLM for simple tasks
- Smaller models often faster and more accurate for focused tasks

*Sources: LinkedIn/Manthan Patel, gradientflow.substack.com, pieces.app*

### Refactoring

| Rank | Model | Why |
|------|-------|-----|
| 1 | **Claude Sonnet 4.5** | Best code quality, idiomatic output |
| 2 | GPT-5.2-Codex | Good at large-scale changes |
| 3 | GPT-5.1-Codex | Fast iterations |

**Research says**: Claude produces cleaner, more idiomatic code, especially in:
- TypeScript
- Python  
- JavaScript

*Sources: SonarSource, digitalapplied.com*

### Test Writing

| Rank | Model | Why |
|------|-------|-----|
| 1 | **GPT-5.1-Codex** | Good at test patterns |
| 2 | Claude Sonnet 4.5 | Better edge case coverage |
| 3 | Gemini 3 Pro | Good for structured outputs |

---

## 3. Reasoning Effort Guidelines

### When to Use Each Level

| Level | When to Use | Performance Impact | Cost Impact |
|-------|-------------|-------------------|-------------|
| **None/Off** | Simple queries, config changes | Baseline | 1× |
| **Low** | Straightforward code, simple bugs | +5-10% accuracy | ~2× |
| **Medium** | Features, moderate complexity | +15-20% accuracy | ~5× |
| **High** | Complex debugging, architecture | +20-30% accuracy | ~10× |
| **Extra High** | Critical/novel problems | +25-35% accuracy | ~15× |

*Source: OpenAI docs, vellum.ai, eval.16x.engineer*

### Real Example (GPT-5 High Reasoning)

| Task | Medium Reasoning | High Reasoning |
|------|------------------|----------------|
| Overall Score | 7.71/10 | **8.86/10** |
| TypeScript narrowing | 1/10 | **8.5/10** |
| Time per task | ~30 seconds | ~3-5 minutes |

**Key Finding**: High reasoning dramatically improves complex tasks but is overkill for simple ones.

*Source: eval.16x.engineer/blog/gpt-5-high-reasoning*

---

## 4. Cost Efficiency Analysis

### Cost per Million Tokens (Factory Multipliers)

| Model | Multiplier | Best Use Case |
|-------|------------|---------------|
| Gemini 3 Flash | **0.2×** | High-volume, simple tasks |
| Droid Core | 0.25× | Bulk automation |
| Haiku 4.5 | 0.4× | Routine tasks |
| GPT-5.1/Codex | 0.5× | General development |
| GPT-5.2/Codex | 0.7× | Complex code |
| Gemini 3 Pro | 0.8× | Research/analysis |
| Sonnet 4.5 | 1.2× | Daily driver, features |
| Opus 4.5 | **2.0×** | Critical work only |

### Potential Savings with Smart Selection

For a typical PRD with mixed complexity:

| Approach | Token Cost |
|----------|------------|
| Always use Opus | 20× baseline |
| Smart selection | 4-6× baseline |
| **Savings** | **70-80%** |

*Source: Factory docs, tokensaver.org*

---

## 5. Speed Benchmarks

| Model | Tokens/Second | Latency | Best For |
|-------|---------------|---------|----------|
| Gemini 3 Flash | ~900 | ~520ms | Real-time |
| GPT-5.2 | ~187 | ~850ms | General |
| Claude Sonnet 4.5 | ~150 | ~760ms | Quality |
| Claude Opus 4.5 | ~100 | ~1000ms | Deep work |

*Source: juheapi.com, vellum.ai*

---

## 6. Research-Backed Selection Matrix

### Quick Reference

| Task Type | Recommended Model | Reasoning | Cost |
|-----------|-------------------|-----------|------|
| Rename/config | Gemini Flash | none | 0.2× |
| Fix typo | Droid Core | none | 0.25× |
| Add import | Haiku 4.5 | off | 0.4× |
| Simple method | GPT-5.1-Codex | low | 0.5× |
| Bug fix (simple) | GPT-5.1-Codex | medium | 0.5× |
| New feature | Sonnet 4.5 | off | 1.2× |
| Bug fix (complex) | Opus 4.5 | low | 2.0× |
| Refactor module | Sonnet 4.5 | low | 1.2× |
| Write tests | GPT-5.1-Codex | low | 0.5× |
| Debug race condition | Opus 4.5 | high | 2.0× |
| Architecture design | Opus 4.5 | high | 2.0× |
| Security review | Opus 4.5 | high | 2.0× |
| Performance optimization | GPT-5.2-Codex | high | 0.7× |

### Decision Tree

```
Is the task trivial (config, rename, typo)?
├─ YES → Gemini Flash (0.2×) or Haiku (0.4×)
└─ NO → Does it require debugging?
         ├─ YES → Is it a complex/multi-system bug?
         │        ├─ YES → Opus 4.5 + high reasoning
         │        └─ NO → Sonnet 4.5 or GPT-5.1-Codex
         └─ NO → Is it writing new code?
                  ├─ YES → Is it complex architecture?
                  │        ├─ YES → Opus 4.5 or GPT-5.2
                  │        └─ NO → GPT-5.1-Codex or Sonnet 4.5
                  └─ NO → GPT-5.1-Codex (general purpose)
```

---

## 7. Key Research Findings Summary

### Claude Models
- **Best for**: Debugging, code quality, understanding context
- **Opus 4.5**: First model to break 80% on SWE-bench
- **Sonnet 4.5**: Best quality/speed/cost balance for coding
- **Haiku 4.5**: Fast, cheap, good for simple tasks

### GPT Models
- **Best for**: New code generation, reasoning, math
- **GPT-5.2**: Best abstract reasoning (52.9% ARC-AGI)
- **GPT-5.1-Codex**: Fast iteration, good code quality
- **Codex-Max**: Extra-high reasoning for hardest problems

### Gemini Models
- **Best for**: Speed, cost efficiency, large context
- **Gemini 3 Flash**: Best budget option, 0.2× cost
- **Gemini 3 Pro**: Good for research/analysis flows

### When Small Models Win
- Simple, repetitive tasks
- Speed-critical applications
- Cost-sensitive projects
- Well-defined, narrow scope tasks

### When Large Models Are Necessary
- Ambiguous requirements
- Multi-step reasoning
- Complex debugging
- Architecture decisions
- Security-critical code

---

## 8. References

1. SWE-bench Official Leaderboards - swebench.com
2. Vellum LLM Leaderboard - vellum.ai/llm-leaderboard
3. Factory Documentation - docs.factory.ai
4. OpenAI Reasoning Models Guide - platform.openai.com/docs/guides/reasoning
5. Anthropic Claude Opus 4.5 Announcement - anthropic.com/news/claude-opus-4-5
6. SonarSource Code Quality Analysis - sonarsource.com/blog
7. GPT-5.1 Prompting Guide - cookbook.openai.com
8. Digital Applied LLM Comparison - digitalapplied.com
9. Vals AI Benchmarks - vals.ai/benchmarks
10. LiveBench - livebench.ai

*Last updated: January 2026*
