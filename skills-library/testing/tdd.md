# Test-Driven Development (TDD)

Based on: obra/superpowers test-driven-development skill

## When This Activates

- Task mentions: test, testing, spec, TDD, unit test, integration test
- Acceptance criteria include test requirements
- Implementing new functionality that should have tests

## The TDD Cycle: RED-GREEN-REFACTOR

### 1. RED: Write a Failing Test

**Before writing ANY implementation code:**

```typescript
// Write the test FIRST
describe('Calculator', () => {
  it('should add two numbers', () => {
    const calc = new Calculator();
    expect(calc.add(2, 3)).toBe(5);
  });
});
```

**Run it and watch it FAIL:**
```bash
npm test -- --grep "add two numbers"
# Expected: FAIL (Calculator doesn't exist yet)
```

**If the test passes without implementation, either:**
- The functionality already exists
- Your test is wrong

### 2. GREEN: Write Minimal Code to Pass

**Write ONLY enough code to make the test pass:**

```typescript
// MINIMAL implementation
class Calculator {
  add(a: number, b: number): number {
    return a + b;
  }
}
```

**Run tests again:**
```bash
npm test -- --grep "add two numbers"
# Expected: PASS
```

**DON'T:**
- Add extra features
- Optimize prematurely
- Add error handling (unless tested)

### 3. REFACTOR: Clean Up

**Now that tests pass, improve the code:**
- Remove duplication
- Improve naming
- Extract methods
- Add types

**Run tests after EVERY refactor:**
```bash
npm test
# Must still pass
```

## Testing Anti-Patterns to Avoid

### 1. Testing Implementation, Not Behavior
```typescript
// BAD: Tests internal state
expect(calc._result).toBe(5);

// GOOD: Tests behavior
expect(calc.getResult()).toBe(5);
```

### 2. Tests That Always Pass
```typescript
// BAD: No assertion
it('should work', () => {
  calc.add(2, 3);
});

// GOOD: Clear assertion
it('should add numbers', () => {
  expect(calc.add(2, 3)).toBe(5);
});
```

### 3. Testing Third-Party Code
```typescript
// BAD: Testing lodash
expect(_.sum([1,2,3])).toBe(6);

// GOOD: Test YOUR code that uses lodash
expect(calc.sumAll([1,2,3])).toBe(6);
```

### 4. Overly Complex Setup
```typescript
// BAD: 50 lines of setup
beforeEach(() => {
  // ... massive setup ...
});

// GOOD: Minimal, focused setup
const createCalc = () => new Calculator();
```

## Test Structure

### File Location
- Colocate with source: `Calculator.test.ts` next to `Calculator.ts`
- Or in `__tests__/` folder

### Naming Convention
```typescript
describe('[Unit Under Test]', () => {
  describe('[Method/Feature]', () => {
    it('should [expected behavior] when [condition]', () => {
      // Arrange
      // Act
      // Assert
    });
  });
});
```

### Example
```typescript
describe('Calculator', () => {
  describe('divide', () => {
    it('should return quotient when dividing valid numbers', () => {
      const calc = new Calculator();
      expect(calc.divide(10, 2)).toBe(5);
    });

    it('should throw error when dividing by zero', () => {
      const calc = new Calculator();
      expect(() => calc.divide(10, 0)).toThrow('Division by zero');
    });
  });
});
```

## Verification Checklist

Before marking task complete:

- [ ] All tests pass: `npm test`
- [ ] Tests were written BEFORE implementation
- [ ] Tests verify BEHAVIOR, not implementation
- [ ] Edge cases covered (null, empty, zero, negative)
- [ ] Error cases tested
- [ ] No skipped tests (`.skip` or `xit`)

## Commands

```bash
# Run all tests
npm test

# Run specific test file
npm test -- Calculator.test.ts

# Run tests matching pattern
npm test -- --grep "divide"

# Run with coverage
npm test -- --coverage

# Watch mode
npm test -- --watch
```
