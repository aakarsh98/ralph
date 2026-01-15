/**
 * UI-TARS Integration for Ralph GUI Testing
 * 
 * Uses the UI-TARS SDK to perform visual GUI automation and verification.
 * UI-TARS is a Vision-Language Model specifically trained for GUI interaction.
 */

import type { GUITest, TestResult } from './types.js';

interface UITarsConfig {
  baseURL: string;
  apiKey: string;
  model: string;
}

interface GUIAgentResult {
  status: 'END' | 'MAX_LOOP' | 'ERROR';
  conversations: Array<{
    from: 'human' | 'gpt' | 'screenshotBase64';
    value: string;
  }>;
}

/**
 * UI-TARS GUI Agent wrapper for visual testing
 */
export class UITarsAgent {
  private config: UITarsConfig;

  constructor(config: UITarsConfig) {
    this.config = config;
  }

  /**
   * Run a GUI automation task using UI-TARS vision model
   */
  async run(instruction: string): Promise<GUIAgentResult> {
    // Dynamic import to handle optional dependency
    const { GUIAgent } = await import('@ui-tars/sdk');
    
    // For browser-based testing, we can use a custom operator
    // or leverage the built-in browser operator
    const { BrowserOperator } = await import('@ui-tars/sdk/operators').catch(() => {
      // Fallback if operators not available in this version
      return { BrowserOperator: null };
    });

    const conversations: GUIAgentResult['conversations'] = [];

    const agent = new GUIAgent({
      model: {
        baseURL: this.config.baseURL,
        apiKey: this.config.apiKey,
        model: this.config.model,
      },
      operator: BrowserOperator ? new BrowserOperator() : undefined,
      onData: ({ data }: any) => {
        if (data.conversations) {
          conversations.push(...data.conversations);
        }
      },
      onError: ({ error }: any) => {
        console.error('[UI-TARS] Error:', error);
      },
    });

    try {
      await agent.run(instruction);
      return { status: 'END', conversations };
    } catch (error: any) {
      console.error('[UI-TARS] Failed:', error.message);
      return { status: 'ERROR', conversations };
    }
  }

  /**
   * Verify a visual condition using UI-TARS
   */
  async verify(instruction: string, expected: string): Promise<{
    passed: boolean;
    reasoning: string;
    confidence: number;
  }> {
    const verifyInstruction = `
Task: Verify the following condition is met.

Instruction: ${instruction}

Expected outcome: ${expected}

Please examine the screen and determine if the expected outcome is satisfied.
If satisfied, perform the action: finished()
If not satisfied, describe what you see instead.
`;

    const result = await this.run(verifyInstruction);
    
    // Parse the result to determine pass/fail
    const passed = result.status === 'END';
    const lastGptResponse = result.conversations
      .filter(c => c.from === 'gpt')
      .pop()?.value || '';

    return {
      passed,
      reasoning: lastGptResponse || (passed ? 'Verification completed successfully' : 'Verification failed'),
      confidence: passed ? 0.9 : 0.3,
    };
  }
}

/**
 * Run a GUI test using UI-TARS
 */
export async function runUITarsTest(
  test: GUITest,
  config: UITarsConfig
): Promise<TestResult> {
  const startTime = Date.now();
  const agent = new UITarsAgent(config);

  try {
    console.log(`[UI-TARS] Running test: ${test.id}`);
    console.log(`[UI-TARS] Instruction: ${test.instruction}`);

    const result = await agent.verify(test.instruction, test.expected);
    const duration = Date.now() - startTime;

    if (result.passed) {
      console.log(`[UI-TARS] PASSED: ${test.id} (confidence: ${result.confidence})`);
    } else {
      console.log(`[UI-TARS] FAILED: ${test.id} - ${result.reasoning}`);
    }

    return {
      testId: test.id,
      passed: result.passed,
      duration,
      error: result.passed ? undefined : result.reasoning,
      logs: [
        `Instruction: ${test.instruction}`,
        `Expected: ${test.expected}`,
        `Reasoning: ${result.reasoning}`,
        `Confidence: ${result.confidence}`,
      ],
    };
  } catch (error: any) {
    const duration = Date.now() - startTime;
    console.error(`[UI-TARS] ERROR: ${test.id} - ${error.message}`);

    return {
      testId: test.id,
      passed: false,
      duration,
      error: error.message,
      logs: [`Error: ${error.message}`],
    };
  }
}

/**
 * Run Agent TARS CLI for complex browser automation
 */
export async function runAgentTars(
  instruction: string,
  options: {
    provider?: string;
    model?: string;
    apiKey?: string;
    headless?: boolean;
    workDir?: string;
  } = {}
): Promise<{ success: boolean; output: string }> {
  const { spawn } = await import('child_process');

  const args = [
    '--provider', options.provider || 'openai',
    '--model', options.model || 'gpt-4o',
  ];

  if (options.apiKey) {
    args.push('--apiKey', options.apiKey);
  }

  if (options.headless) {
    args.push('--headless');
  }

  args.push('--instruction', instruction);

  return new Promise((resolve) => {
    const proc = spawn('npx', ['@agent-tars/cli', ...args], {
      cwd: options.workDir,
      stdio: ['ignore', 'pipe', 'pipe'],
      shell: true,
    });

    let output = '';
    let errorOutput = '';

    proc.stdout?.on('data', (data) => {
      output += data.toString();
    });

    proc.stderr?.on('data', (data) => {
      errorOutput += data.toString();
    });

    proc.on('close', (code) => {
      resolve({
        success: code === 0,
        output: output || errorOutput,
      });
    });

    proc.on('error', (err) => {
      resolve({
        success: false,
        output: err.message,
      });
    });
  });
}
