import * as fs from 'fs';
import * as path from 'path';
import { detectProjectType } from './project-detector.js';
import { startDevServer, stopDevServer } from './dev-server.js';
import { initBrowser, closeBrowser, runBrowserTest, takeScreenshot, navigateTo } from './browser-tester.js';
import { runGUITest } from './vlm-verifier.js';
import type { PRDWithGUITests, TestResult, ProjectConfig, GUITest, BrowserTest } from './types.js';

interface TestRunConfig {
  prdPath: string;
  storyId?: string;
  headless?: boolean;
  screenshotDir?: string;
  skipBuild?: boolean;
  vlmProvider?: 'ui-tars' | 'agent-tars' | 'volcengine' | 'huggingface' | 'openai' | 'anthropic' | 'custom';
  vlmModel?: string;
  vlmBaseUrl?: string;
  vlmApiKey?: string;
}

interface TestRunResult {
  storyId: string;
  totalTests: number;
  passedTests: number;
  failedTests: number;
  results: TestResult[];
  duration: number;
}

export async function runTestsForStory(config: TestRunConfig): Promise<TestRunResult> {
  const startTime = Date.now();
  const results: TestResult[] = [];

  // Read PRD
  const prdContent = fs.readFileSync(config.prdPath, 'utf-8');
  const prd: PRDWithGUITests = JSON.parse(prdContent);

  // Find the story
  const story = config.storyId
    ? prd.userStories.find((s) => s.id === config.storyId)
    : prd.userStories.find((s) => !s.passes);

  if (!story) {
    console.log('[TestRunner] No story found to test');
    return {
      storyId: config.storyId || 'none',
      totalTests: 0,
      passedTests: 0,
      failedTests: 0,
      results: [],
      duration: Date.now() - startTime
    };
  }

  console.log(`[TestRunner] Testing story: ${story.id} - ${story.title}`);

  // Check if story has GUI or browser tests
  const hasGUITests = story.guiTests && story.guiTests.length > 0;
  const hasBrowserTests = story.browserTests && story.browserTests.length > 0;

  if (!hasGUITests && !hasBrowserTests) {
    console.log('[TestRunner] No GUI or browser tests defined for this story');
    return {
      storyId: story.id,
      totalTests: 0,
      passedTests: 0,
      failedTests: 0,
      results: [],
      duration: Date.now() - startTime
    };
  }

  // Setup screenshot directory
  const screenshotDir = config.screenshotDir || path.join(path.dirname(config.prdPath), 'screenshots');
  if (!fs.existsSync(screenshotDir)) {
    fs.mkdirSync(screenshotDir, { recursive: true });
  }

  // Detect project and get config
  const projectDir = path.dirname(config.prdPath);
  const detected = detectProjectType(projectDir);
  
  // Merge with PRD config
  const projectConfig: ProjectConfig = {
    ...detected.config,
    name: prd.project,
    rootDir: projectDir,
    devCommand: prd.guiTestConfig?.devCommand || detected.config.devCommand,
    devUrl: prd.guiTestConfig?.devUrl || detected.config.devUrl,
    devPort: prd.guiTestConfig?.devPort || detected.config.devPort,
    startupWaitMs: prd.guiTestConfig?.startupWaitMs || detected.config.startupWaitMs
  };

  let serverStarted = false;

  try {
    // Start dev server if needed
    if (projectConfig.devCommand) {
      console.log('[TestRunner] Starting dev server...');
      await startDevServer(projectConfig);
      serverStarted = true;
    }

    // Initialize browser
    await initBrowser(config.headless ?? true);

    // Run browser tests
    if (hasBrowserTests && story.browserTests) {
      console.log(`[TestRunner] Running ${story.browserTests.length} browser tests`);
      
      for (const test of story.browserTests) {
        const result = await runBrowserTest(test, screenshotDir);
        results.push(result);
      }
    }

    // Run GUI tests (UI-TARS based visual verification)
    if (hasGUITests && story.guiTests) {
      const vlmConfig = {
        provider: config.vlmProvider || 'ui-tars',
        model: config.vlmModel || 'ui-tars-1.5-7b',
        baseUrl: config.vlmBaseUrl || process.env.UI_TARS_BASE_URL,
        apiKey: config.vlmApiKey || process.env.UI_TARS_API_KEY || process.env.VLM_API_KEY || ''
      };

      if (!vlmConfig.apiKey) {
        console.warn('[TestRunner] No VLM API key provided. Skipping GUI tests.');
      } else {
        console.log(`[TestRunner] Running ${story.guiTests.length} GUI tests`);

        for (const test of story.guiTests) {
          // Navigate and take screenshot
          const testUrl = projectConfig.devUrl || 'http://localhost:3000';
          await navigateTo(testUrl);
          
          const screenshotPath = path.join(screenshotDir, `${test.id}-current.png`);
          await takeScreenshot(screenshotPath);

          const result = await runGUITest(test, screenshotPath, vlmConfig as any);
          results.push(result);
        }
      }
    }
  } finally {
    // Cleanup
    await closeBrowser();
    if (serverStarted) {
      await stopDevServer();
    }
  }

  const passedTests = results.filter((r) => r.passed).length;
  const failedTests = results.filter((r) => !r.passed).length;

  console.log(`\n[TestRunner] Results for ${story.id}:`);
  console.log(`  Total: ${results.length}`);
  console.log(`  Passed: ${passedTests}`);
  console.log(`  Failed: ${failedTests}`);

  return {
    storyId: story.id,
    totalTests: results.length,
    passedTests,
    failedTests,
    results,
    duration: Date.now() - startTime
  };
}

// CLI entry point
async function main() {
  const args = process.argv.slice(2);
  
  if (args.length === 0 || args.includes('--help')) {
    console.log(`
GUI Test Runner for Ralph

Usage:
  npx ts-node test-runner.ts <prd.json> [options]

Options:
  --story <id>        Test specific story ID
  --headless          Run browser in headless mode (default: true)
  --no-headless       Show browser window
  --vlm-provider      VLM provider: openai, anthropic, volcengine, custom
  --vlm-model         VLM model name
  --vlm-api-key       VLM API key (or set VLM_API_KEY env var)

Example:
  npx ts-node test-runner.ts ./prd.json --story US-002 --no-headless
`);
    process.exit(0);
  }

  const prdPath = path.resolve(args[0]);
  
  const config: TestRunConfig = {
    prdPath,
    headless: !args.includes('--no-headless'),
    storyId: args.includes('--story') ? args[args.indexOf('--story') + 1] : undefined,
    vlmProvider: args.includes('--vlm-provider') 
      ? args[args.indexOf('--vlm-provider') + 1] as any 
      : undefined,
    vlmModel: args.includes('--vlm-model') ? args[args.indexOf('--vlm-model') + 1] : undefined,
    vlmApiKey: args.includes('--vlm-api-key') ? args[args.indexOf('--vlm-api-key') + 1] : undefined
  };

  try {
    const result = await runTestsForStory(config);
    
    // Output result as JSON for Ralph to parse
    console.log('\n--- TEST RESULTS ---');
    console.log(JSON.stringify(result, null, 2));
    
    process.exit(result.failedTests > 0 ? 1 : 0);
  } catch (error: any) {
    console.error('[TestRunner] Fatal error:', error.message);
    process.exit(1);
  }
}

main().catch(console.error);
