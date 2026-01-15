# Ralph GUI Test Module (UI-TARS Powered)

Automated GUI and Browser testing for the Ralph automation system using **UI-TARS** - a Vision-Language Model specifically trained for GUI interaction and automation.

## Features

- **UI-TARS Integration**: Uses UI-TARS SDK and Agent TARS for intelligent visual testing
- **Project Auto-Detection**: Automatically detects Next.js, Vite, CRA, Remix, Express, Fastify, Django, Flask
- **Dev Server Management**: Starts/stops dev servers with health checking
- **Browser Testing**: Puppeteer-based DOM testing with assertions
- **Visual GUI Testing**: UI-TARS powered visual verification (sees and understands the UI)
- **Cross-Platform**: Works on Windows, macOS, and Linux

## Installation

```bash
cd droid/tools/gui-test
npm install
npm run build
```

## Usage

### Command Line

```bash
# Basic usage - tests first incomplete story (uses UI-TARS by default)
./gui-test.sh ./path/to/prd.json

# Test specific story
./gui-test.sh ./prd.json US-002

# Show browser window (non-headless)
./gui-test.sh ./prd.json --no-headless

# Use Agent TARS (full browser automation)
./gui-test.sh ./prd.json --vlm-provider=agent-tars

# Use VolcEngine's Doubao-UI-TARS model
./gui-test.sh ./prd.json --vlm-provider=volcengine --vlm-model=doubao-1-5-ui-tars
```

### Windows PowerShell

```powershell
.\gui-test.ps1 .\prd.json
.\gui-test.ps1 .\prd.json -StoryId US-002 -NoHeadless
.\gui-test.ps1 .\prd.json -VlmProvider agent-tars
```

### Environment Variables

```bash
# UI-TARS Configuration (Recommended)
export UI_TARS_API_KEY="your-api-key"   # Required for UI-TARS tests
export UI_TARS_BASE_URL="https://..."   # Your UI-TARS model endpoint

# Alternative providers
export VLM_PROVIDER="ui-tars"           # ui-tars, agent-tars, volcengine, huggingface
export VLM_MODEL="ui-tars-1.5-7b"       # Model to use
```

## Model Options

| Provider | Model | Description | Cost |
|----------|-------|-------------|------|
| `ui-tars` | `ui-tars-1.5-7b` | Self-hosted UI-TARS model | Free (self-host) |
| `huggingface` | `UI-TARS-1.5-7B` | Hugging Face endpoint | Pay per use |
| `volcengine` | `doubao-1-5-ui-tars` | ByteDance's cloud UI-TARS | Pay per use |
| `agent-tars` | (any) | Full Agent TARS automation | Varies |

## PRD Schema

Add `guiTestConfig` and test definitions to your `prd.json`:

```json
{
  "project": "MyApp",
  "guiTestConfig": {
    "devCommand": "npm run dev",
    "devUrl": "http://localhost:3000",
    "devPort": 3000,
    "startupWaitMs": 5000
  },
  "userStories": [
    {
      "id": "US-001",
      "title": "Feature title",
      "browserTests": [...],
      "guiTests": [...]
    }
  ]
}
```

## Test Types

### Browser Tests (Puppeteer-based)

Programmatic DOM testing with actions and assertions:

```json
{
  "id": "BT-001",
  "name": "Button click test",
  "url": "http://localhost:3000",
  "actions": [
    { "type": "click", "selector": "#submit-btn" },
    { "type": "wait", "delay": 1000 },
    { "type": "screenshot", "filename": "after-click.png" }
  ],
  "assertions": [
    { "type": "exists", "selector": ".success-message" },
    { "type": "text", "selector": ".status", "expected": "Saved" }
  ]
}
```

#### Available Actions

| Action | Parameters | Description |
|--------|------------|-------------|
| `click` | `selector` | Click element |
| `type` | `selector`, `value` | Type text into input |
| `navigate` | `url` | Navigate to URL |
| `wait` | `delay` | Wait milliseconds |
| `scroll` | `direction` | Scroll up/down |
| `hover` | `selector` | Hover over element |
| `screenshot` | `filename` | Take screenshot |

#### Available Assertions

| Assertion | Parameters | Description |
|-----------|------------|-------------|
| `exists` | `selector` | Element exists in DOM |
| `visible` | `selector` | Element is visible |
| `text` | `selector`, `expected` | Element contains text |
| `count` | `selector`, `expected` | Number of elements |
| `attribute` | `selector`, `attribute`, `expected` | Attribute value |

### GUI Tests (UI-TARS Visual Verification)

Visual verification using UI-TARS vision-language model:

```json
{
  "id": "GT-001",
  "instruction": "Look at the dashboard and verify the chart is displaying correctly",
  "expected": "A bar chart showing monthly sales data should be visible with labeled axes",
  "screenshotAfter": true
}
```

**How UI-TARS works:**
1. Takes a screenshot of the current browser state
2. UI-TARS model "sees" and understands the UI
3. Verifies if the expected outcome is satisfied
4. Can perform actions (click, type) if needed to navigate

Returns:
- `passed`: Whether the expected outcome was observed
- `reasoning`: What UI-TARS observed on screen
- `confidence`: 0.0-1.0 confidence score

## Integration with Ralph

### Add to qualityChecks

```json
{
  "qualityChecks": {
    "typecheck": "npm run typecheck",
    "lint": "npm run lint",
    "test": "npm test",
    "guiTest": "bash ../tools/gui-test/gui-test.sh ./prd.json"
  }
}
```

### In droid-prompt.md

Add GUI test step after implementation:

```markdown
### Step 5b: GUI Tests (if defined)
If the story has `browserTests` or `guiTests` defined:
```bash
bash tools/gui-test/gui-test.sh prd.json [STORY_ID]
```
GUI tests must pass before marking story complete.
```

## Supported Project Types

| Type | Detection | Default Dev Command | Default Port |
|------|-----------|---------------------|--------------|
| Next.js | `next` in deps | `npm run dev` | 3000 |
| Vite | `vite` in deps | `npm run dev` | 5173 |
| CRA | `react-scripts` in deps | `npm start` | 3000 |
| Remix | `@remix-run/*` in deps | `npm run dev` | 3000 |
| Express | `express` in deps | `npm start` | 3000 |
| Fastify | `fastify` in deps | `npm start` | 3000 |
| Django | `manage.py` exists | `python manage.py runserver` | 8000 |
| Flask | Flask import in app.py | `flask run` | 5000 |

## Output

Test results are output as JSON:

```json
{
  "storyId": "US-002",
  "totalTests": 3,
  "passedTests": 2,
  "failedTests": 1,
  "results": [
    {
      "testId": "BT-002-1",
      "passed": true,
      "duration": 2340,
      "screenshots": ["screenshots/task-list.png"]
    }
  ],
  "duration": 15230
}
```

## Troubleshooting

### Browser won't start
- Ensure Chrome/Chromium is installed
- Try with `--no-headless` to see errors

### Dev server timeout
- Increase `startupWaitMs` in `guiTestConfig`
- Check if port is already in use

### VLM tests failing
- Verify `VLM_API_KEY` is set
- Check model supports vision (e.g., `gpt-4o`, `claude-3-5-sonnet`)
- Review screenshots in `screenshots/` directory

## Architecture

```
gui-test/
├── src/
│   ├── types.ts           # TypeScript interfaces
│   ├── project-detector.ts # Auto-detect project type
│   ├── dev-server.ts      # Start/stop dev servers
│   ├── browser-tester.ts  # Puppeteer browser tests
│   ├── vlm-verifier.ts    # VLM-based visual tests
│   ├── test-runner.ts     # Main orchestrator
│   └── index.ts           # Module exports
├── gui-test.sh            # Bash runner
├── gui-test.ps1           # PowerShell runner
├── package.json
└── README.md
```
