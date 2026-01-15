# Executing Plans

Based on: obra/superpowers executing-plans skill

## When This Activates

- Working through a task list
- Following an implementation plan
- PRD with multiple stories

## Execution Process

### 1. Read the Plan
```markdown
Before starting:
- Read the entire plan
- Understand dependencies
- Note verification steps
```

### 2. Execute One Task at a Time

**DO:**
```
1. Read Task 1
2. Implement Task 1
3. Verify Task 1
4. Commit Task 1
5. Move to Task 2
```

**DON'T:**
```
1. Read all tasks
2. Implement everything
3. Verify at the end
4. One big commit
```

### 3. Verify Before Moving On

```bash
# After EACH task:
npm test
npm run typecheck
npm run lint

# Only proceed if all pass
```

### 4. Commit After Each Task

```bash
git add -A
git commit -m "feat: [Task description]"
```

## Batch Execution (for Ralph)

When running autonomously:

### Single Story Per Iteration
```
Iteration 1: Task 1 → verify → commit
Iteration 2: Task 2 → verify → commit
Iteration 3: Task 3 → verify → commit
```

### Within One Story
```
Story has 3 sub-tasks:
1. Create model → verify
2. Add service → verify
3. Add endpoint → verify
All verified → commit → mark story complete
```

## Handling Failures

### Test Failure
```
1. Read error message
2. Identify failing test
3. Fix the implementation
4. Re-run verification
5. Continue only when passing
```

### Blocked by Dependency
```
1. Identify missing dependency
2. Check if previous task was incomplete
3. Complete prerequisite first
4. Return to blocked task
```

### Unexpected Issue
```
1. Document the issue
2. Check if it's a blocker
3. If blocker: stop and report
4. If not: work around and note
```

## Progress Tracking

### After Each Task
```markdown
## Progress Log

### [TIME] - Task 1: Create Calculator
- Status: Complete
- Files: src/Calculator.ts
- Tests: 3 passing
- Commit: abc123
```

### After Each Story
```markdown
## [DATE] - US-001: Basic Calculator

### Tasks Completed
1. ✓ Create Calculator class
2. ✓ Add operations
3. ✓ Add tests

### Verification
- All 12 tests passing
- TypeScript compiles
- Lint clean

### Commit: def456
```

## Execution Checklist

For each task:
- [ ] Read task requirements
- [ ] Check dependencies are complete
- [ ] Implement the task
- [ ] Run verification
- [ ] All checks pass
- [ ] Commit changes
- [ ] Update progress log

## Anti-Patterns

**DON'T:**
- Skip verification steps
- Batch multiple tasks in one commit
- Proceed when tests fail
- Ignore dependency order
- Rush through without checking

**DO:**
- Verify after each task
- Commit frequently
- Stop on failures
- Follow dependency order
- Document progress

## Recovery

### If You Get Stuck
```
1. Stop and assess
2. Check what's working
3. Review recent changes: git diff HEAD~3
4. Consider reverting: git revert HEAD
5. Re-approach with smaller steps
```

### If Tests Break
```
1. Don't panic
2. Check git status
3. Review what changed
4. Fix or revert
5. Verify before continuing
```
