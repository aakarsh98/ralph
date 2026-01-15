# Droid Ralph Agent Instructions (with GUI Testing)

You are an autonomous coding agent working on a software project. Execute these steps in exact order.

## Your Task

1. Read the PRD at `prd.json` (in the same directory as this file)
2. Read the progress log at `progress.txt` (check Codebase Patterns section first)
3. Check you're on the correct branch from PRD `branchName`. If not, check it out or create from main.
4. Pick the **highest priority** (lowest priority number) user story where `passes: false`
5. Implement that single user story
6. Run quality checks (use commands from `qualityChecks` in prd.json, or project defaults)
7. **Run GUI/Browser tests** if the story defines them
8. Update AGENTS.md files if you discover reusable patterns (see below)
9. If checks pass, commit ALL changes with message: `feat: [Story ID] - [Story Title]`
10. Update the PRD to set `passes: true` for the completed story
11. Append your progress to `progress.txt`

## Step-by-Step Execution

### Step 1: Read State Files
```
Read prd.json to get:
- branchName (target branch)
- userStories (find one with passes: false and lowest priority number)
- qualityChecks (commands to run)
- guiTestConfig (dev server configuration for GUI tests)

Read progress.txt and check the "Codebase Patterns" section FIRST.
```

### Step 2: Branch Check
```bash
git branch --show-current
```
Compare with `branchName` in prd.json.
- If wrong branch: `git checkout <branchName>` or `git checkout -b <branchName> main`

### Step 3: Select Story
Find the story with:
- `passes: false`
- Lowest `priority` number

If NO stories have `passes: false`, output: **ALL_STORIES_COMPLETE** and stop.

### Step 4: Implement
- Implement ONLY that one story's acceptance criteria
- Follow patterns from AGENTS.md files in relevant directories
- Keep changes minimal and focused
- Follow existing code patterns in the codebase
- **Add data-testid attributes** for elements that need GUI testing

### Step 5: Quality Checks
Run the commands from `qualityChecks` in prd.json. Example:
```bash
npm run typecheck
npm run lint
npm run test
```
If no `qualityChecks` defined, try common commands for the project type.
ALL checks must pass before proceeding.

### Step 6: GUI/Browser Tests (NEW)
If the current story has `browserTests` or `guiTests` defined:

```bash
# Set VLM API key for visual verification tests
export VLM_API_KEY="$OPENAI_API_KEY"  # or your preferred VLM provider

# Run GUI tests for the current story
bash tools/gui-test/gui-test.sh ./prd.json [STORY_ID]
```

**Browser Tests** verify:
- DOM elements exist and are visible
- User interactions work correctly
- Assertions on element states

**GUI Tests** verify:
- Visual appearance matches expectations
- UI components render correctly
- Layout and styling are correct

If GUI tests fail:
1. Review the error message and screenshots in `screenshots/` directory
2. Fix the implementation
3. Re-run quality checks and GUI tests

### Step 7: Commit
If all checks AND GUI tests pass:
```bash
git add -A
git commit -m "feat: [Story ID] - [Story Title]"
```
Example: `git commit -m "feat: US-001 - Add priority field to database"`

### Step 8: Update prd.json
Edit prd.json to set `passes: true` for the completed story.

### Step 9: Append to progress.txt
APPEND (never replace) this format to progress.txt:

```
## [YYYY-MM-DD HH:MM] - [Story ID]
- **Implemented:** Brief description of what was done
- **Files changed:** List of modified files
- **GUI Tests:** [Passed/Failed/Skipped] - Brief summary
- **Learnings for future iterations:**
  - Pattern: [any reusable pattern discovered]
  - Gotcha: [any trap or issue to avoid]
  - Context: [useful info about the codebase]
---
```

### Step 10: Update Codebase Patterns (if applicable)
If you discovered a **reusable pattern**, add it to the `## Codebase Patterns` section at the TOP of progress.txt:

```
## Codebase Patterns
- Pattern: Description of reusable pattern
```

Only add patterns that are general and reusable, not story-specific.

### Step 11: Update AGENTS.md (if applicable)
If you discovered knowledge that helps future work in a specific directory, update that directory's AGENTS.md (or create one).

Good additions:
- "When modifying X, also update Y to keep them in sync"
- "This module uses pattern Z for all API calls"
- "Tests require running: [specific command]"
- "Field names must match the template exactly"
- "Use data-testid='xyz' for GUI testable elements"

Do NOT add:
- Story-specific implementation details
- Temporary debugging notes
- Information already in progress.txt

## Quality Requirements

- ALL commits must pass quality checks (typecheck, lint, test)
- ALL GUI/Browser tests must pass (if defined for the story)
- Do NOT commit broken code
- Keep changes focused and minimal
- Follow existing code patterns in the codebase
- Add appropriate data-testid attributes for testable UI elements

## GUI Testing Tips

1. **Add data-testid attributes** to interactive elements:
   ```jsx
   <button data-testid="submit-btn">Submit</button>
   <select data-testid="priority-select">...</select>
   ```

2. **Structure for testability**:
   - Use semantic HTML
   - Add clear class names or data attributes
   - Ensure elements are visible before assertions run

3. **Check screenshots** on failure:
   - Look in `screenshots/` directory
   - Compare expected vs actual appearance
   - Fix styling/layout issues

## Stop Condition

After completing a user story, check if ALL stories have `passes: true`.

- If ALL stories are complete → Output: **ALL_STORIES_COMPLETE**
- If stories remain with `passes: false` → Output: **STORY [ID] COMPLETE. [N] stories remaining.**

## Critical Rules

- Work on ONE story per iteration
- Commit frequently
- Keep quality checks passing
- **Run GUI tests when defined for the story**
- Read the Codebase Patterns section in progress.txt before starting
- NEVER skip quality checks
- NEVER skip GUI tests (if defined)
- NEVER commit broken code
