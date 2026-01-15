import { spawn, ChildProcess } from 'child_process';
import * as http from 'http';
import * as https from 'https';
import type { ProjectConfig } from './types.js';

let serverProcess: ChildProcess | null = null;

export async function startDevServer(config: ProjectConfig): Promise<{ pid: number; url: string }> {
  if (!config.devCommand) {
    throw new Error('No dev command specified in project config');
  }

  console.log(`[DevServer] Starting: ${config.devCommand}`);
  console.log(`[DevServer] Working directory: ${config.rootDir}`);

  const isWindows = process.platform === 'win32';
  const shell = isWindows ? 'cmd.exe' : '/bin/bash';
  const shellArgs = isWindows ? ['/c', config.devCommand] : ['-c', config.devCommand];

  serverProcess = spawn(shell, shellArgs, {
    cwd: config.rootDir,
    stdio: ['ignore', 'pipe', 'pipe'],
    detached: !isWindows,
    env: {
      ...process.env,
      PORT: String(config.devPort || 3000),
      NODE_ENV: 'development'
    }
  });

  const pid = serverProcess.pid!;
  console.log(`[DevServer] Process started with PID: ${pid}`);

  // Log stdout/stderr
  serverProcess.stdout?.on('data', (data) => {
    console.log(`[DevServer] ${data.toString().trim()}`);
  });

  serverProcess.stderr?.on('data', (data) => {
    console.error(`[DevServer:err] ${data.toString().trim()}`);
  });

  serverProcess.on('error', (err) => {
    console.error(`[DevServer] Process error:`, err);
  });

  serverProcess.on('exit', (code) => {
    console.log(`[DevServer] Process exited with code: ${code}`);
    serverProcess = null;
  });

  // Wait for server to be ready
  const url = config.devUrl || `http://localhost:${config.devPort || 3000}`;
  const healthPath = config.healthCheckPath || '/';
  const startupWait = config.startupWaitMs || 5000;

  console.log(`[DevServer] Waiting ${startupWait}ms for server startup...`);
  await sleep(startupWait);

  console.log(`[DevServer] Checking health at: ${url}${healthPath}`);
  const isHealthy = await waitForServer(url + healthPath, 30000);

  if (!isHealthy) {
    await stopDevServer();
    throw new Error(`Server failed to start at ${url}`);
  }

  console.log(`[DevServer] Server is ready at: ${url}`);
  return { pid, url };
}

export async function stopDevServer(): Promise<void> {
  if (!serverProcess) {
    console.log('[DevServer] No server process to stop');
    return;
  }

  console.log(`[DevServer] Stopping server (PID: ${serverProcess.pid})`);

  return new Promise((resolve) => {
    const isWindows = process.platform === 'win32';

    if (isWindows) {
      // On Windows, use taskkill to kill the process tree
      spawn('taskkill', ['/pid', String(serverProcess!.pid), '/f', '/t'], {
        stdio: 'ignore'
      });
    } else {
      // On Unix, kill the process group
      try {
        process.kill(-serverProcess!.pid!, 'SIGTERM');
      } catch (e) {
        // Process might already be dead
      }
    }

    setTimeout(() => {
      serverProcess = null;
      console.log('[DevServer] Server stopped');
      resolve();
    }, 2000);
  });
}

async function waitForServer(url: string, timeoutMs: number): Promise<boolean> {
  const startTime = Date.now();
  const checkInterval = 1000;

  while (Date.now() - startTime < timeoutMs) {
    try {
      const isUp = await checkServerHealth(url);
      if (isUp) return true;
    } catch {
      // Server not ready yet
    }
    await sleep(checkInterval);
  }

  return false;
}

function checkServerHealth(url: string): Promise<boolean> {
  return new Promise((resolve) => {
    const client = url.startsWith('https') ? https : http;
    const timeout = setTimeout(() => resolve(false), 5000);

    const req = client.get(url, (res) => {
      clearTimeout(timeout);
      resolve(res.statusCode !== undefined && res.statusCode < 500);
    });

    req.on('error', () => {
      clearTimeout(timeout);
      resolve(false);
    });
  });
}

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

// Handle process exit
process.on('exit', () => {
  if (serverProcess) {
    stopDevServer();
  }
});

process.on('SIGINT', async () => {
  await stopDevServer();
  process.exit(0);
});

process.on('SIGTERM', async () => {
  await stopDevServer();
  process.exit(0);
});
