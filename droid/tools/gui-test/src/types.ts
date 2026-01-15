export interface ProjectConfig {
  name: string;
  rootDir: string;
  buildCommand?: string;
  devCommand?: string;
  devUrl?: string;
  devPort?: number;
  startupWaitMs?: number;
  healthCheckPath?: string;
}

export interface GUITest {
  id: string;
  instruction: string;
  expected: string;
  screenshotBefore?: boolean;
  screenshotAfter?: boolean;
  timeout?: number;
}

export interface BrowserTest {
  id: string;
  name: string;
  url: string;
  actions: BrowserAction[];
  assertions: BrowserAssertion[];
}

export interface BrowserAction {
  type: 'click' | 'type' | 'navigate' | 'wait' | 'scroll' | 'hover' | 'screenshot';
  selector?: string;
  value?: string;
  url?: string;
  delay?: number;
  direction?: 'up' | 'down';
  filename?: string;
}

export interface BrowserAssertion {
  type: 'exists' | 'visible' | 'text' | 'count' | 'attribute' | 'screenshot-match';
  selector?: string;
  expected?: string | number;
  attribute?: string;
  tolerance?: number;
}

export interface TestResult {
  testId: string;
  passed: boolean;
  duration: number;
  error?: string;
  screenshots?: string[];
  logs?: string[];
}

export interface GUITestConfig {
  project: ProjectConfig;
  guiTests?: GUITest[];
  browserTests?: BrowserTest[];
  vlmProvider?: 'openai' | 'anthropic' | 'volcengine' | 'custom';
  vlmModel?: string;
  vlmBaseUrl?: string;
  vlmApiKey?: string;
}

export interface PRDWithGUITests {
  project: string;
  branchName: string;
  description: string;
  qualityChecks?: Record<string, string>;
  guiTestConfig?: {
    devCommand: string;
    devUrl: string;
    devPort: number;
    startupWaitMs?: number;
  };
  userStories: UserStoryWithGUITests[];
}

export interface UserStoryWithGUITests {
  id: string;
  title: string;
  description: string;
  acceptanceCriteria: string[];
  priority: number;
  passes: boolean;
  notes?: string;
  guiTests?: GUITest[];
  browserTests?: BrowserTest[];
}
