# Pattern Learning Skill

This skill ensures you learn from and contribute to the project's collective knowledge.

## When This Activates

ALWAYS - patterns compound across iterations.

## Phase 1: Load Existing Patterns

Before ANY implementation:

### 1.1 Find Pattern Sources
```bash
find . -name "AGENTS.md" -type f
cat progress.txt | head -50  # Check Codebase Patterns section
```

### 1.2 Extract Actionable Patterns

From AGENTS.md, note:
- **Naming conventions**: How are files, classes, functions named?
- **Import patterns**: How are imports organized?
- **Error handling**: How does this project handle errors?
- **Testing patterns**: How are tests structured?
- **Architecture**: Key decisions and their rationale
- **Gotchas**: Things that will trip you up

### 1.3 Document What You Loaded

```markdown
## Patterns Loaded
- Naming: Components use PascalCase
- Imports: Third-party first, then local, alphabetized
- Tests: Colocated with source files as *.test.ts
- Gotcha: Must run `npm run build` before tests
```

## Phase 2: Apply Patterns

During implementation:

### 2.1 Check Before Writing
- Does this file follow the naming convention?
- Are imports in the right order?
- Does error handling match the pattern?

### 2.2 Verify Consistency
```bash
# Example: Check if naming matches
ls src/components/  # See existing naming pattern
```

### 2.3 Flag Deviations
If you MUST deviate from a pattern, document why:
```markdown
**Deviation**: Used lowercase filename for compatibility with legacy code
**Reason**: External system expects lowercase
```

## Phase 3: Discover New Patterns

During implementation, watch for:

### 3.1 Repeated Structures
If you see the same pattern 3+ times, it's worth documenting:
```markdown
## Code Patterns
### API Response Handling
All API calls use this pattern:
```typescript
try {
  const response = await api.call();
  return response.data;
} catch (error) {
  logger.error(error);
  throw new ApiError(error.message);
}
```
```

### 3.2 Non-Obvious Requirements
If you had to figure something out that wasn't documented:
```markdown
## Known Gotchas
### Database Migrations
- Must run `npm run db:migrate` before tests
- Migrations are in `prisma/migrations/`
- Seed data resets on each test run
```

### 3.3 Dependencies
If you discovered module relationships:
```markdown
## Dependencies
- `UserService` depends on `AuthService` for token validation
- `PaymentController` must be initialized after `StripeService`
```

## Phase 4: Record Learnings

### 4.1 Update AGENTS.md
Add genuinely reusable knowledge:
```markdown
## Recent Learnings
### [DATE] - [CONTEXT]
- **Discovery**: [What you learned]
- **Impact**: [How it affects future work]
```

### 4.2 Update progress.txt Codebase Patterns
```markdown
## Codebase Patterns
- [New pattern discovered]
```

### 4.3 Report in Progress Log
```markdown
### Patterns Applied
- [Pattern from AGENTS.md that helped]

### Patterns Discovered
- [New pattern added to AGENTS.md]
```

## Pattern Quality Checklist

Before adding a pattern, verify:
- [ ] Is this specific to THIS project? (not general knowledge)
- [ ] Would this help a future iteration work faster?
- [ ] Would knowing this have prevented a mistake?
- [ ] Is it stable? (not likely to change soon)

## Anti-Patterns (Don't Add)

- Generic language/framework documentation
- Temporary debugging notes
- Story-specific implementation details
- Personal preferences not reflected in codebase
- Outdated patterns from old code
