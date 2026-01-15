# Ralph Quickstart Guide

Step-by-step instructions for using Droid Ralph with your projects.

---

## Prerequisites

Before using Ralph, ensure you have:

1. **Droid CLI** installed ([docs.factory.ai](https://docs.factory.ai))
2. **jq** for JSON processing
3. **Git** initialized in your project

### Quick Install Check

```bash
# Check Droid CLI
droid --version

# Check jq
jq --version

# Check Git
git --version
```

---

## Step 1: Clone Ralph Repository

```bash
git clone https://github.com/aakarsh-nadella-c4/ralph.git
cd ralph
```

---

## Step 2: Choose Your Mode

Ralph has three modes:

| Mode | Script | Description |
|------|--------|-------------|
| **Normal** | `droid/normal/droid-ralph.sh` | Trust-based, faster |
| **Strict** | `droid/strict/droid-ralph.sh` | Verification required |
| **Smart** | `droid/strict/ralph-smart.sh` | Strict + intelligent model selection |

**Recommendation**: Start with **Smart** mode for best cost/quality balance.

---

## Step 3: Create Your PRD

Create a `prd.json` file in your project directory:

```json
{
  "project": "My Project Name",
  "description": "Brief description of what you're building",
  "userStories": [
    {
      "id": "US-001",
      "title": "Add user authentication",
      "description": "Implement login/logout functionality",
      "priority": 1,
      "acceptanceCriteria": [
        "User can register with email/password",
        "User can log in with credentials",
        "User can log out",
        "Sessions persist across browser refresh"
      ],
      "passes": false
    },
    {
      "id": "US-002",
      "title": "Add password reset",
      "description": "Allow users to reset forgotten passwords",
      "priority": 2,
      "acceptanceCriteria": [
        "User can request password reset via email",
        "Reset link expires after 24 hours",
        "User can set new password"
      ],
      "passes": false
    }
  ]
}
```

### PRD Best Practices

1. **Keep stories small** - Each should complete in one context window
2. **Be specific** - Clear acceptance criteria help verification
3. **Set priorities** - Ralph processes in priority order
4. **Use VERIFY: prefix** - For strict mode verification commands

Example with VERIFY prefix:
```json
{
  "acceptanceCriteria": [
    "VERIFY: npm test -- --testPathPattern=auth passes",
    "VERIFY: npm run typecheck exits with code 0",
    "Login form renders on /login route"
  ]
}
```

---

## Step 4: Set Up AGENTS.md (Recommended)

Create an `AGENTS.md` file in your project root to help Ralph understand your codebase:

```markdown
# Project Intelligence

## Code Patterns
- Use TypeScript for all new files
- Follow existing naming conventions (camelCase)
- Import order: external libs, then internal modules

## Testing
- Run tests: `npm test`
- Run typecheck: `npm run typecheck`
- Run lint: `npm run lint`

## Gotchas
- Database connection requires .env setup
- Auth middleware must be applied before route handlers

## Architecture
- src/components/ - React components
- src/api/ - Backend routes
- src/utils/ - Shared utilities
```

Ralph reads this file at the start of each iteration and updates it with new learnings.

---

## Step 5: Copy Ralph Files to Your Project

Option A: **Copy the script** (simplest)

```bash
# Copy smart mode to your project
cp ralph/droid/strict/ralph-smart.sh /path/to/your/project/
cp ralph/droid/strict/prompt.md /path/to/your/project/

# Make executable
chmod +x /path/to/your/project/ralph-smart.sh
```

Option B: **Reference Ralph from anywhere** (recommended)

```bash
# Add to your .bashrc or .zshrc
export RALPH_HOME="/path/to/ralph"
alias ralph="$RALPH_HOME/droid/strict/ralph-smart.sh"
```

---

## Step 6: Run Ralph

### Basic Usage

```bash
cd /path/to/your/project

# Run with default 10 iterations
./ralph-smart.sh

# Run with specific max iterations
./ralph-smart.sh 20
```

### What Happens

1. Ralph reads your `prd.json`
2. Finds the first story where `passes: false`
3. Assesses complexity (trivial → critical)
4. Selects optimal model based on task type
5. Executes the story with Droid
6. Verifies acceptance criteria
7. Updates `prd.json` and `progress.txt`
8. Repeats until all stories complete

### Monitor Progress

```bash
# Watch the progress file
tail -f progress.txt

# Check metrics
cat metrics.json | jq .
```

---

## Step 7: Review Results

After Ralph completes:

1. **Check prd.json** - See which stories passed
2. **Review progress.txt** - Read learnings from each iteration
3. **Check metrics.json** - See model usage and timing
4. **Run your tests** - Verify everything works

```bash
# See completed stories
cat prd.json | jq '.userStories[] | select(.passes == true) | .title'

# See remaining stories
cat prd.json | jq '.userStories[] | select(.passes == false) | .title'
```

---

## Advanced Usage

### Override Model for Specific Story

Add a `model` field to force a specific model:

```json
{
  "id": "US-003",
  "title": "Security audit",
  "model": "claude-opus-4-5-20251101",
  "reasoning": "high",
  "acceptanceCriteria": [...]
}
```

### Use Skills Library

Copy the skills library to your project:

```bash
cp -r ralph/skills-library /path/to/your/project/
```

Ralph will automatically load relevant skills based on task keywords.

### Compare Modes

Run both normal and strict modes to compare:

```bash
cd ralph/droid
./compare.sh /path/to/your/project
```

---

## Troubleshooting

### "droid: command not found"

Install Droid CLI:
```bash
# See https://docs.factory.ai for installation
```

### "jq: command not found"

Install jq:
```bash
# macOS
brew install jq

# Ubuntu/Debian
sudo apt install jq

# Windows (chocolatey)
choco install jq
```

### Stories not completing

1. Check if acceptance criteria are too vague
2. Add VERIFY: prefix for testable criteria
3. Break large stories into smaller ones
4. Check progress.txt for error patterns

### Model selection not working

Ensure the script has access to model definitions:
```bash
# Check models file exists
cat ralph/droid/models/MODELS.json | jq '.models | keys'
```

---

## Example Projects

### React App

```json
{
  "project": "Todo App",
  "userStories": [
    {
      "id": "US-001",
      "title": "Setup project structure",
      "priority": 1,
      "acceptanceCriteria": [
        "VERIFY: npm run build exits successfully",
        "src/components directory exists",
        "TypeScript configured"
      ],
      "passes": false
    }
  ]
}
```

### API Backend

```json
{
  "project": "REST API",
  "userStories": [
    {
      "id": "US-001",
      "title": "Add health check endpoint",
      "priority": 1,
      "acceptanceCriteria": [
        "VERIFY: curl localhost:3000/health returns 200",
        "Response includes version number",
        "Response time < 100ms"
      ],
      "passes": false
    }
  ]
}
```

---

## Cost Optimization Tips

1. **Start with Smart mode** - Uses cheapest effective model
2. **Keep stories small** - Reduces context per iteration
3. **Use AGENTS.md** - Prevents repeated mistakes
4. **Batch simple changes** - Group config/rename tasks
5. **Reserve Opus for complex work** - Debugging, architecture

### Expected Savings

| PRD Type | Fixed Opus Cost | Smart Mode Cost | Savings |
|----------|-----------------|-----------------|---------|
| 10 simple stories | 20× | 2-4× | 80-90% |
| Mixed complexity | 20× | 5-8× | 60-75% |
| All complex | 20× | 15-20× | 0-25% |

---

## Next Steps

1. **Join the community** - Share your patterns and learnings
2. **Contribute skills** - Add to the skills library
3. **Report issues** - Help improve Ralph

---

*Happy autonomous coding!*
