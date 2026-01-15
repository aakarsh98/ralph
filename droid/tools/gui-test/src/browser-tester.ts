import puppeteer, { Browser, Page } from 'puppeteer';
import * as fs from 'fs';
import * as path from 'path';
import type { BrowserTest, BrowserAction, BrowserAssertion, TestResult } from './types.js';

let browser: Browser | null = null;
let page: Page | null = null;

export async function initBrowser(headless: boolean = true): Promise<void> {
  console.log(`[Browser] Launching browser (headless: ${headless})`);
  
  browser = await puppeteer.launch({
    headless: headless ? 'shell' : false,
    args: [
      '--no-sandbox',
      '--disable-setuid-sandbox',
      '--disable-dev-shm-usage',
      '--disable-gpu'
    ],
    defaultViewport: { width: 1920, height: 1080 }
  });

  page = await browser.newPage();
  
  // Set up console logging
  page.on('console', (msg) => {
    console.log(`[Browser:console] ${msg.type()}: ${msg.text()}`);
  });

  page.on('pageerror', (err) => {
    console.error(`[Browser:error] ${err.message}`);
  });

  console.log('[Browser] Browser initialized');
}

export async function closeBrowser(): Promise<void> {
  if (browser) {
    await browser.close();
    browser = null;
    page = null;
    console.log('[Browser] Browser closed');
  }
}

export async function runBrowserTest(test: BrowserTest, screenshotDir: string): Promise<TestResult> {
  if (!page) {
    throw new Error('Browser not initialized. Call initBrowser() first.');
  }

  const startTime = Date.now();
  const screenshots: string[] = [];
  const logs: string[] = [];

  try {
    logs.push(`Starting test: ${test.name}`);
    console.log(`[BrowserTest] Running: ${test.name}`);

    // Navigate to URL
    await page.goto(test.url, { waitUntil: 'networkidle2', timeout: 30000 });
    logs.push(`Navigated to: ${test.url}`);

    // Execute actions
    for (const action of test.actions) {
      await executeAction(page, action, screenshotDir, screenshots);
      logs.push(`Action executed: ${action.type}`);
    }

    // Run assertions
    for (const assertion of test.assertions) {
      const passed = await checkAssertion(page, assertion);
      if (!passed) {
        throw new Error(`Assertion failed: ${assertion.type} on ${assertion.selector}`);
      }
      logs.push(`Assertion passed: ${assertion.type}`);
    }

    const duration = Date.now() - startTime;
    console.log(`[BrowserTest] PASSED: ${test.name} (${duration}ms)`);

    return {
      testId: test.id,
      passed: true,
      duration,
      screenshots,
      logs
    };
  } catch (error: any) {
    const duration = Date.now() - startTime;
    console.error(`[BrowserTest] FAILED: ${test.name} - ${error.message}`);

    // Take failure screenshot
    const failScreenshot = path.join(screenshotDir, `${test.id}-failure.png`);
    await page.screenshot({ path: failScreenshot, fullPage: true });
    screenshots.push(failScreenshot);

    return {
      testId: test.id,
      passed: false,
      duration,
      error: error.message,
      screenshots,
      logs
    };
  }
}

async function executeAction(
  page: Page,
  action: BrowserAction,
  screenshotDir: string,
  screenshots: string[]
): Promise<void> {
  switch (action.type) {
    case 'click':
      if (!action.selector) throw new Error('Click action requires selector');
      await page.waitForSelector(action.selector, { timeout: 10000 });
      await page.click(action.selector);
      break;

    case 'type':
      if (!action.selector || !action.value) throw new Error('Type action requires selector and value');
      await page.waitForSelector(action.selector, { timeout: 10000 });
      await page.type(action.selector, action.value);
      break;

    case 'navigate':
      if (!action.url) throw new Error('Navigate action requires url');
      await page.goto(action.url, { waitUntil: 'networkidle2' });
      break;

    case 'wait':
      await new Promise((r) => setTimeout(r, action.delay || 1000));
      break;

    case 'scroll':
      const direction = action.direction || 'down';
      await page.evaluate((dir) => {
        window.scrollBy(0, dir === 'down' ? 500 : -500);
      }, direction);
      break;

    case 'hover':
      if (!action.selector) throw new Error('Hover action requires selector');
      await page.waitForSelector(action.selector, { timeout: 10000 });
      await page.hover(action.selector);
      break;

    case 'screenshot':
      const filename = action.filename || `screenshot-${Date.now()}.png`;
      const screenshotPath = path.join(screenshotDir, filename);
      await page.screenshot({ path: screenshotPath, fullPage: true });
      screenshots.push(screenshotPath);
      break;
  }
}

async function checkAssertion(page: Page, assertion: BrowserAssertion): Promise<boolean> {
  switch (assertion.type) {
    case 'exists':
      if (!assertion.selector) throw new Error('Exists assertion requires selector');
      const exists = await page.$(assertion.selector);
      return exists !== null;

    case 'visible':
      if (!assertion.selector) throw new Error('Visible assertion requires selector');
      const visible = await page.$eval(assertion.selector, (el) => {
        const style = window.getComputedStyle(el);
        return style.display !== 'none' && style.visibility !== 'hidden' && style.opacity !== '0';
      }).catch(() => false);
      return visible;

    case 'text':
      if (!assertion.selector || assertion.expected === undefined) {
        throw new Error('Text assertion requires selector and expected');
      }
      const text = await page.$eval(assertion.selector, (el) => el.textContent?.trim() || '');
      return text.includes(String(assertion.expected));

    case 'count':
      if (!assertion.selector || assertion.expected === undefined) {
        throw new Error('Count assertion requires selector and expected');
      }
      const elements = await page.$$(assertion.selector);
      return elements.length === Number(assertion.expected);

    case 'attribute':
      if (!assertion.selector || !assertion.attribute || assertion.expected === undefined) {
        throw new Error('Attribute assertion requires selector, attribute, and expected');
      }
      const attrValue = await page.$eval(
        assertion.selector,
        (el, attr) => el.getAttribute(attr),
        assertion.attribute
      );
      return attrValue === String(assertion.expected);

    default:
      throw new Error(`Unknown assertion type: ${assertion.type}`);
  }
}

export async function takeScreenshot(filename: string, fullPage: boolean = true): Promise<string> {
  if (!page) throw new Error('Browser not initialized');
  await page.screenshot({ path: filename, fullPage });
  return filename;
}

export async function navigateTo(url: string): Promise<void> {
  if (!page) throw new Error('Browser not initialized');
  await page.goto(url, { waitUntil: 'networkidle2' });
}

export async function getPageContent(): Promise<string> {
  if (!page) throw new Error('Browser not initialized');
  return await page.content();
}

export async function evaluateScript<T>(script: string): Promise<T> {
  if (!page) throw new Error('Browser not initialized');
  return await page.evaluate(script) as T;
}
