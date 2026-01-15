import * as fs from 'fs';
import * as path from 'path';
import type { GUITest, TestResult } from './types.js';
import { runUITarsTest, runAgentTars } from './ui-tars-agent.js';

interface VLMConfig {
  provider: 'ui-tars' | 'agent-tars' | 'volcengine' | 'huggingface' | 'openai' | 'anthropic' | 'custom';
  model: string;
  baseUrl?: string;
  apiKey: string;
}

interface VLMResponse {
  passed: boolean;
  reasoning: string;
  confidence: number;
  details?: string;
}

export class VLMVerifier {
  private config: VLMConfig;

  constructor(config: VLMConfig) {
    this.config = config;
  }

  async verifyScreenshot(
    screenshotPath: string,
    instruction: string,
    expectedOutcome: string
  ): Promise<VLMResponse> {
    // For UI-TARS based providers, use the SDK directly (doesn't need screenshot)
    if (this.config.provider === 'ui-tars' || this.config.provider === 'huggingface') {
      return await this.verifyWithUITars(instruction, expectedOutcome);
    }

    if (this.config.provider === 'agent-tars') {
      return await this.verifyWithAgentTars(instruction, expectedOutcome);
    }

    // For other providers, use screenshot-based verification
    const imageBase64 = fs.readFileSync(screenshotPath).toString('base64');
    const mimeType = screenshotPath.endsWith('.png') ? 'image/png' : 'image/jpeg';
    const prompt = this.buildVerificationPrompt(instruction, expectedOutcome);

    switch (this.config.provider) {
      case 'volcengine':
        return await this.verifyWithVolcEngine(imageBase64, mimeType, prompt);
      case 'openai':
        return await this.verifyWithOpenAI(imageBase64, mimeType, prompt);
      case 'anthropic':
        return await this.verifyWithAnthropic(imageBase64, mimeType, prompt);
      case 'custom':
        return await this.verifyWithCustomEndpoint(imageBase64, mimeType, prompt);
      default:
        throw new Error(`Unsupported VLM provider: ${this.config.provider}`);
    }
  }

  private async verifyWithUITars(
    instruction: string,
    expectedOutcome: string
  ): Promise<VLMResponse> {
    const { UITarsAgent } = await import('./ui-tars-agent.js');
    
    const agent = new UITarsAgent({
      baseURL: this.config.baseUrl || 'https://api.openai.com/v1',
      apiKey: this.config.apiKey,
      model: this.config.model || 'ui-tars-1.5-7b',
    });

    const result = await agent.verify(instruction, expectedOutcome);
    
    return {
      passed: result.passed,
      reasoning: result.reasoning,
      confidence: result.confidence,
    };
  }

  private async verifyWithAgentTars(
    instruction: string,
    expectedOutcome: string
  ): Promise<VLMResponse> {
    const fullInstruction = `Verify: ${instruction}. Expected: ${expectedOutcome}. If the condition is met, report success.`;
    
    const result = await runAgentTars(fullInstruction, {
      provider: 'volcengine',
      model: this.config.model || 'doubao-1-5-ui-tars',
      apiKey: this.config.apiKey,
      headless: true,
    });

    return {
      passed: result.success,
      reasoning: result.output,
      confidence: result.success ? 0.85 : 0.3,
    };
  }

  private async verifyWithVolcEngine(
    imageBase64: string,
    mimeType: string,
    prompt: string
  ): Promise<VLMResponse> {
    // VolcEngine uses OpenAI-compatible API for Doubao models
    const baseUrl = this.config.baseUrl || 'https://ark.cn-beijing.volces.com/api/v3';
    return await this.verifyWithCustomEndpoint(imageBase64, mimeType, prompt, baseUrl);
  }

  private buildVerificationPrompt(instruction: string, expectedOutcome: string): string {
    return `You are a UI testing assistant. Analyze the provided screenshot and determine if the expected outcome is satisfied.

## Task Instruction
${instruction}

## Expected Outcome
${expectedOutcome}

## Your Task
1. Carefully examine the screenshot
2. Determine if the expected outcome is visible/satisfied
3. Provide your assessment

Respond in JSON format:
{
  "passed": true/false,
  "reasoning": "Brief explanation of what you observed",
  "confidence": 0.0-1.0,
  "details": "Any additional observations"
}`;
  }

  private async verifyWithOpenAI(
    imageBase64: string,
    mimeType: string,
    prompt: string
  ): Promise<VLMResponse> {
    const OpenAI = (await import('openai')).default;
    const client = new OpenAI({
      apiKey: this.config.apiKey,
      baseURL: this.config.baseUrl
    });

    const response = await client.chat.completions.create({
      model: this.config.model,
      messages: [
        {
          role: 'user',
          content: [
            { type: 'text', text: prompt },
            {
              type: 'image_url',
              image_url: { url: `data:${mimeType};base64,${imageBase64}` }
            }
          ]
        }
      ],
      max_tokens: 1024,
      response_format: { type: 'json_object' }
    });

    const content = response.choices[0]?.message?.content || '{}';
    return this.parseVLMResponse(content);
  }

  private async verifyWithAnthropic(
    imageBase64: string,
    mimeType: string,
    prompt: string
  ): Promise<VLMResponse> {
    const Anthropic = (await import('@anthropic-ai/sdk')).default;
    const client = new Anthropic({ apiKey: this.config.apiKey });

    const response = await client.messages.create({
      model: this.config.model,
      max_tokens: 1024,
      messages: [
        {
          role: 'user',
          content: [
            {
              type: 'image',
              source: {
                type: 'base64',
                media_type: mimeType as 'image/png' | 'image/jpeg' | 'image/gif' | 'image/webp',
                data: imageBase64
              }
            },
            { type: 'text', text: prompt }
          ]
        }
      ]
    });

    const content = response.content[0]?.type === 'text' ? response.content[0].text : '{}';
    return this.parseVLMResponse(content);
  }

  private async verifyWithCustomEndpoint(
    imageBase64: string,
    mimeType: string,
    prompt: string
  ): Promise<VLMResponse> {
    const baseUrl = this.config.baseUrl || 'https://api.openai.com/v1';
    
    const response = await fetch(`${baseUrl}/chat/completions`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${this.config.apiKey}`
      },
      body: JSON.stringify({
        model: this.config.model,
        messages: [
          {
            role: 'user',
            content: [
              { type: 'text', text: prompt },
              {
                type: 'image_url',
                image_url: { url: `data:${mimeType};base64,${imageBase64}` }
              }
            ]
          }
        ],
        max_tokens: 1024
      })
    });

    const data = await response.json() as any;
    const content = data.choices?.[0]?.message?.content || '{}';
    return this.parseVLMResponse(content);
  }

  private parseVLMResponse(content: string): VLMResponse {
    try {
      // Extract JSON from response (handle markdown code blocks)
      const jsonMatch = content.match(/```json\s*([\s\S]*?)\s*```/) || 
                        content.match(/```\s*([\s\S]*?)\s*```/) ||
                        [null, content];
      const jsonStr = jsonMatch[1] || content;
      
      const parsed = JSON.parse(jsonStr.trim());
      return {
        passed: Boolean(parsed.passed),
        reasoning: parsed.reasoning || 'No reasoning provided',
        confidence: typeof parsed.confidence === 'number' ? parsed.confidence : 0.5,
        details: parsed.details
      };
    } catch (e) {
      console.error('[VLM] Failed to parse response:', content);
      return {
        passed: false,
        reasoning: 'Failed to parse VLM response',
        confidence: 0,
        details: content
      };
    }
  }
}

export async function runGUITest(
  test: GUITest,
  screenshotPath: string,
  vlmConfig: VLMConfig
): Promise<TestResult> {
  const startTime = Date.now();
  const verifier = new VLMVerifier(vlmConfig);

  try {
    console.log(`[GUITest] Running: ${test.id} - ${test.instruction}`);

    const result = await verifier.verifyScreenshot(
      screenshotPath,
      test.instruction,
      test.expected
    );

    const duration = Date.now() - startTime;

    if (result.passed) {
      console.log(`[GUITest] PASSED: ${test.id} (confidence: ${result.confidence})`);
    } else {
      console.log(`[GUITest] FAILED: ${test.id} - ${result.reasoning}`);
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
        result.details ? `Details: ${result.details}` : ''
      ].filter(Boolean)
    };
  } catch (error: any) {
    const duration = Date.now() - startTime;
    console.error(`[GUITest] ERROR: ${test.id} - ${error.message}`);

    return {
      testId: test.id,
      passed: false,
      duration,
      error: error.message,
      logs: [`Error: ${error.message}`]
    };
  }
}
