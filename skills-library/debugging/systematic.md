# Systematic Debugging

Based on: obra/superpowers systematic-debugging skill

## When This Activates

- Task mentions: bug, debug, fix, error, issue, broken, fails, not working
- Test failures need investigation
- Unexpected behavior

## The 4-Phase Process

### Phase 1: REPRODUCE

**Before anything else, reproduce the bug consistently.**

```bash
# Document exact steps to reproduce
1. Start the app: npm run dev
2. Navigate to /login
3. Enter invalid password
4. Click submit
5. EXPECTED: Error message
6. ACTUAL: App crashes
```

**Create a reproduction test if possible:**
```typescript
it('should show error on invalid password', () => {
  // This test should FAIL initially (proving the bug exists)
  login('user', 'wrong');
  expect(getErrorMessage()).toBe('Invalid password');
});
```

### Phase 2: ISOLATE

**Narrow down the location of the bug.**

#### Binary Search
```
Is the bug in frontend or backend?
  → Frontend
Is it in the form component or the validation?
  → Validation
Is it in the password check or the error display?
  → Password check
```

#### Add Strategic Logging
```typescript
function validatePassword(password: string) {
  console.log('validatePassword called with:', password);  // DEBUG
  const result = checkPassword(password);
  console.log('checkPassword result:', result);  // DEBUG
  return result;
}
```

#### Check Recent Changes
```bash
git log --oneline -10
git diff HEAD~3
# Did a recent change break this?
```

### Phase 3: FIX

**Fix the ROOT CAUSE, not the symptom.**

#### Identify Root Cause
```
Symptom: App crashes on invalid password
Surface cause: Null pointer exception
Root cause: checkPassword returns null instead of false
```

#### Write Test First (TDD)
```typescript
it('should return false for invalid password, not null', () => {
  expect(checkPassword('wrong')).toBe(false);
});
```

#### Implement Fix
```typescript
function checkPassword(password: string): boolean {
  const result = doPasswordCheck(password);
  return result ?? false;  // Never return null
}
```

### Phase 4: VERIFY

**Prove the bug is fixed AND no regressions.**

```bash
# Run the reproduction test
npm test -- --grep "invalid password"
# Should PASS now

# Run full test suite
npm test
# All tests should pass

# Manual verification
# Follow original reproduction steps
# Bug should no longer occur
```

## Debugging Techniques

### 1. Root Cause Tracing
```
Start: App crashes
Why? → Null pointer in validatePassword
Why null? → checkPassword returns null
Why? → Database query returns null for unknown user
Why? → Missing default fallback
ROOT CAUSE: No default return value
```

### 2. Defense in Depth
Add multiple layers of protection:
```typescript
// Layer 1: Type safety
function check(p: string): boolean

// Layer 2: Runtime validation
if (typeof p !== 'string') throw new Error('Invalid input');

// Layer 3: Null safety
return result ?? false;

// Layer 4: Error boundary
try { ... } catch (e) { logger.error(e); return false; }
```

### 3. Condition-Based Waiting
For async/timing issues:
```typescript
// BAD: Fixed timeout
await sleep(1000);
expect(element).toBeVisible();

// GOOD: Wait for condition
await waitFor(() => expect(element).toBeVisible());
```

## Documentation Template

```markdown
## Bug: [Brief Description]

### Reproduction
1. [Step 1]
2. [Step 2]
3. Expected: [X]
4. Actual: [Y]

### Root Cause Analysis
- Surface symptom: [what you see]
- Immediate cause: [first level why]
- Root cause: [underlying issue]

### Fix
- File: [path]
- Change: [description]

### Verification
- [ ] Reproduction test passes
- [ ] All tests pass
- [ ] Manual verification complete
```

## Anti-Patterns

**DON'T:**
- Guess and check randomly
- Fix symptoms instead of root cause
- Remove code "just to see"
- Skip reproduction
- Assume you know the cause

**DO:**
- Reproduce consistently first
- Follow evidence systematically
- Fix root cause
- Verify comprehensively
- Document findings
