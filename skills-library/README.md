# Skills Library for Droid Ralph

A collection of reusable skills that Ralph can automatically discover and load based on task context.

## Overview

Skills are specialized instruction sets that help the AI handle specific types of tasks more effectively. Instead of loading all skills for every task (wasteful), Ralph intelligently selects relevant skills based on the task at hand.

## Sources

This library includes skills adapted from:
- [Anthropic Skills](https://github.com/anthropics/skills) - Official Claude Code skills
- [Superpowers](https://github.com/obra/superpowers) - Community development workflow skills

## Directory Structure

```
skills-library/
├── REGISTRY.json          # Index of all skills with triggers
├── README.md              # This file
│
├── core/                  # Always-active skills
│   ├── skill-selector.md  # Auto-selects relevant skills
│   └── pattern-learning.md # AGENTS.md integration
│
├── testing/               # Test-related skills
│   ├── tdd.md            # Test-Driven Development
│   └── verification.md    # Verification before completion
│
├── debugging/             # Bug fixing skills
│   └── systematic.md      # Systematic debugging process
│
├── planning/              # Planning skills
│   ├── writing-plans.md   # Creating task breakdowns
│   └── executing-plans.md # Following plans
│
├── documents/             # Document generation
│   ├── pdf.md
│   ├── docx.md
│   ├── xlsx.md
│   └── pptx.md
│
└── frontend/              # Frontend development
    ├── design.md
    └── webapp-testing.md
```

## How Skills Are Selected

### 1. Trigger Keywords

Each skill has trigger keywords in REGISTRY.json:

```json
"test-driven-development": {
  "triggers": ["test", "testing", "TDD", "unit test"]
}
```

### 2. Task Analysis

When Ralph starts a task, it:
1. Reads the task description
2. Scans for trigger keywords
3. Loads matching skills
4. Applies skill instructions

### 3. Example Selection

**Task**: "Fix the login bug where authentication fails"

**Matched triggers**: "fix", "bug"

**Skills loaded**:
- `systematic-debugging` (for root cause analysis)
- `verification-before-completion` (to confirm fix)

## Available Skills

### Core (Always Active)
| Skill | Description |
|-------|-------------|
| skill-selector | Selects relevant skills for current task |
| pattern-learning | Learn from and update AGENTS.md |

### Testing
| Skill | Triggers |
|-------|----------|
| test-driven-development | test, TDD, unit test, spec |
| verification-before-completion | verify, check, confirm |

### Debugging
| Skill | Triggers |
|-------|----------|
| systematic-debugging | bug, debug, fix, error, broken |

### Planning
| Skill | Triggers |
|-------|----------|
| writing-plans | plan, design, architect |
| executing-plans | execute, implement, build |

### Documents
| Skill | Triggers |
|-------|----------|
| pdf | pdf, PDF, report |
| docx | docx, word, document |
| xlsx | xlsx, excel, spreadsheet |
| pptx | pptx, powerpoint, presentation |

### Frontend
| Skill | Triggers |
|-------|----------|
| frontend-design | UI, frontend, component, CSS |
| webapp-testing | e2e, playwright, cypress |

## Adding New Skills

1. Create a markdown file in the appropriate category folder
2. Add an entry to REGISTRY.json
3. Include trigger keywords
4. Document when the skill should activate

### Skill Template

```markdown
# [Skill Name]

Based on: [source]

## When This Activates

- [Trigger conditions]

## Process

### Step 1: [Name]
[Instructions]

### Step 2: [Name]
[Instructions]

## Verification

[How to verify skill was applied correctly]

## Anti-Patterns

**DON'T:**
- [What to avoid]

**DO:**
- [Best practices]
```

## Integration with Ralph

Ralph's prompt includes:

```markdown
## PHASE 0.5: SKILL SELECTION

1. Read REGISTRY.json
2. Match task against triggers
3. Load relevant skills
4. Apply during implementation
5. Document which skills were used
```

This happens automatically before implementation begins.
