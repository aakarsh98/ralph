# Writing Plans

Based on: obra/superpowers writing-plans skill

## When This Activates

- Large feature that needs breakdown
- Task mentions: plan, design, architect, break down, decompose
- PRD has complex stories that need sub-tasks

## Planning Principles

### 1. Bite-Sized Tasks
Each task should take 2-5 minutes for an AI to complete.

**Too Big:**
```
- Build the authentication system
```

**Right Size:**
```
- Create User model with email/password fields
- Add password hashing utility function
- Create login endpoint
- Add JWT token generation
- Create auth middleware
```

### 2. Exact File Paths
Every task must specify exact files to create/modify.

**Vague:**
```
- Add the user component
```

**Specific:**
```
- Create src/components/UserProfile.tsx
- Add UserProfile.test.tsx
- Update src/components/index.ts to export
```

### 3. Verification Steps
Each task must have a way to verify completion.

```markdown
## Task: Add User model

### Files
- Create: src/models/User.ts

### Implementation
```typescript
export interface User {
  id: string;
  email: string;
  passwordHash: string;
}
```

### Verification
- [ ] File exists at src/models/User.ts
- [ ] TypeScript compiles: `npx tsc --noEmit`
- [ ] Can import: `import { User } from './models/User'`
```

## Plan Structure

```markdown
# Implementation Plan: [Feature Name]

## Overview
[Brief description of what we're building]

## Dependencies
[What must exist before we start]

## Tasks

### Task 1: [Name]
**Files:** [list of files]
**Dependencies:** [previous tasks or external deps]

**Steps:**
1. [Step 1]
2. [Step 2]

**Verification:**
- [ ] [How to verify this works]

### Task 2: [Name]
...
```

## Task Ordering

### Correct Order (Dependencies First)
```
1. Database models (no dependencies)
2. Service layer (depends on models)
3. API endpoints (depends on services)
4. UI components (depends on API)
5. Integration tests (depends on all above)
```

### Wrong Order
```
1. UI components (will fail - no API yet)
2. API endpoints (will fail - no services)
...
```

## Estimation Guidelines

| Task Type | Time |
|-----------|------|
| Create simple model/type | 2 min |
| Create utility function | 3 min |
| Create API endpoint | 5 min |
| Create UI component | 5 min |
| Write tests for existing code | 3-5 min |
| Refactor single file | 3 min |

**If a task takes > 5 min, break it down further.**

## Example Plan

```markdown
# Implementation Plan: Calculator App

## Overview
Simple calculator with basic operations.

## Tasks

### Task 1: Create Calculator Class
**Files:** src/Calculator.ts, src/Calculator.test.ts

**Steps:**
1. Create Calculator class with constructor
2. Add add(a, b) method
3. Add test file with basic test

**Verification:**
- [ ] `npm test -- Calculator.test.ts` passes

### Task 2: Add Subtract Method
**Files:** src/Calculator.ts, src/Calculator.test.ts
**Dependencies:** Task 1

**Steps:**
1. Add subtract(a, b) method to Calculator
2. Add tests for subtract

**Verification:**
- [ ] `npm test -- --grep subtract` passes

### Task 3: Add Multiply Method
**Files:** src/Calculator.ts, src/Calculator.test.ts
**Dependencies:** Task 1

**Steps:**
1. Add multiply(a, b) method
2. Add tests for multiply

**Verification:**
- [ ] `npm test -- --grep multiply` passes
```

## Anti-Patterns

**DON'T:**
- Create tasks without verification steps
- Use vague file references
- Make tasks too large
- Skip dependency analysis
- Assume implicit order

**DO:**
- Be specific about files
- Include verification for each task
- Keep tasks small (2-5 min)
- Order by dependencies
- Include test tasks
