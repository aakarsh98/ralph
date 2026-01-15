# Skill Selector

This skill automatically activates to help you select relevant skills for the current task.

## When This Activates

ALWAYS - at the start of every task, before any implementation.

## How to Use

### Step 1: Analyze the Task

Read the current user story or task and identify:
- What type of work is this? (testing, debugging, frontend, backend, docs, etc.)
- What technologies are involved?
- What's the expected output?

### Step 2: Check the Skills Registry

Review `skills-library/REGISTRY.json` and match task keywords against skill triggers.

```
Task: "Add unit tests for the Calculator class"
Triggers matched: "test", "unit test"
Skills to load: test-driven-development, verification-before-completion
```

### Step 3: Load Relevant Skills

For each matched skill:
1. Read the skill file from `skills-library/[category]/[skill].md`
2. Apply the skill's instructions during implementation
3. Note which skills were used in progress.txt

### Step 4: Report Skills Used

After completing the task, document:
```markdown
### Skills Applied
- test-driven-development: Wrote failing test first
- verification-before-completion: Verified all tests pass
```

## Trigger Keywords Reference

| Category | Triggers |
|----------|----------|
| Testing | test, testing, spec, TDD, unit test, integration |
| Debugging | bug, debug, fix, error, broken, fails, issue |
| Planning | plan, design, architect, break down |
| Documents | pdf, docx, xlsx, pptx, document, report |
| Frontend | UI, frontend, design, component, CSS, React |

## Example Selection

**Task**: "Fix the login bug where users can't authenticate"

**Analysis**:
- Type: Bug fix (debugging)
- Keywords: "fix", "bug"
- Technologies: Authentication

**Skills Selected**:
1. `systematic-debugging` - For root cause analysis
2. `verification-before-completion` - To ensure fix works

**Not Selected**:
- `test-driven-development` - Not primarily about writing new tests
- `frontend-design` - Not a UI task

## When NOT to Load Skills

- Simple file reads or exploration
- Quick one-line fixes with obvious solutions
- Documentation-only changes
- Configuration updates

Keep skill loading efficient - only load what's actually needed.
