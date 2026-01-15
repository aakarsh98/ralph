# Verification Before Completion

Based on: obra/superpowers verification-before-completion skill

## When This Activates

- Before marking any task as complete
- After implementing a fix
- Before committing code

## Core Principle

**Never claim something works without PROOF.**

## Verification Steps

### Step 1: Run the Tests
```bash
npm test
# All tests must pass
```

### Step 2: Run Type Checks
```bash
npm run typecheck
# No type errors
```

### Step 3: Run Linting
```bash
npm run lint
# No lint errors
```

### Step 4: Verify the Specific Change

**For bug fixes:**
```bash
# Reproduce the original bug scenario
# Confirm it no longer occurs
```

**For new features:**
```bash
# Test the happy path
# Test edge cases
# Test error cases
```

**For UI changes:**
```bash
# Visual inspection in browser
# Test different viewport sizes
# Test keyboard navigation
```

### Step 5: Check for Regressions
```bash
# Run full test suite
npm test

# Check related functionality still works
```

## Verification Evidence Format

Document your verification:

```markdown
### Verification Report

| Check | Command/Method | Result |
|-------|----------------|--------|
| Tests pass | `npm test` | ✓ 42 tests passed |
| Types | `npm run typecheck` | ✓ No errors |
| Lint | `npm run lint` | ✓ No warnings |
| Feature works | Manual test: added 2+3 | ✓ Returns 5 |
| Edge case | divide(5, 0) | ✓ Throws error |
```

## Red Flags - Stop and Investigate

- [ ] Tests pass but feature doesn't work manually
- [ ] Had to skip or comment out tests
- [ ] "Works on my machine" without proof
- [ ] Relying on console.log instead of tests
- [ ] Changes to unrelated files

## Verification Checklist

Before marking complete:

```markdown
- [ ] All automated tests pass
- [ ] Type check passes
- [ ] Lint passes
- [ ] Manually verified the specific change
- [ ] No regressions in related functionality
- [ ] Documented verification evidence
```

## When Verification Fails

### If tests fail:
1. Read the error message
2. Identify root cause
3. Fix the issue
4. Re-run verification

### If manual verification fails:
1. The implementation is incomplete
2. Do NOT mark as complete
3. Continue implementing
4. Re-verify

### If you can't verify:
1. Add a test that would verify
2. Run the test
3. Now you can verify

## Anti-Patterns

**DON'T:**
- Skip verification because "it's a simple change"
- Trust that it works without running it
- Verify in one environment only
- Ignore failing tests
- Mark complete before verification

**DO:**
- Verify EVERY change
- Document the verification
- Test in the actual environment
- Fix failing tests before proceeding
- Be skeptical of your own code
