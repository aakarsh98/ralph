---
description: Run GUI and browser tests for a story
arguments:
  - name: story_id
    description: Story ID to test (optional, defaults to first incomplete)
  - name: prd_path
    description: Path to prd.json (optional, defaults to ./prd.json)
---

Run GUI and browser tests for the specified story.

1. Read the PRD at `{{ prd_path | default: "./prd.json" }}`
2. Find story `{{ story_id }}` (or first incomplete story if not specified)
3. If the story has `browserTests` or `guiTests` defined:
   - Start the dev server using `guiTestConfig.devCommand`
   - Wait for server to be ready
   - Run browser tests (Puppeteer-based DOM assertions)
   - Run GUI tests (VLM-based visual verification)
   - Stop the dev server
4. Report results: passed/failed tests with details

Execute the test runner:
```bash
bash tools/gui-test/gui-test.sh {{ prd_path | default: "./prd.json" }} {{ story_id }}
```

If VLM tests are needed, ensure `VLM_API_KEY` environment variable is set.
