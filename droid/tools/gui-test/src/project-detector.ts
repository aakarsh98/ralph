import * as fs from 'fs';
import * as path from 'path';
import type { ProjectConfig } from './types.js';

interface DetectedProject {
  type: 'nextjs' | 'vite' | 'cra' | 'remix' | 'express' | 'fastify' | 'django' | 'flask' | 'unknown';
  config: Partial<ProjectConfig>;
}

export function detectProjectType(rootDir: string): DetectedProject {
  const packageJsonPath = path.join(rootDir, 'package.json');
  const pyprojectPath = path.join(rootDir, 'pyproject.toml');
  const requirementsPath = path.join(rootDir, 'requirements.txt');

  // Check for Node.js projects
  if (fs.existsSync(packageJsonPath)) {
    const packageJson = JSON.parse(fs.readFileSync(packageJsonPath, 'utf-8'));
    return detectNodeProject(packageJson, rootDir);
  }

  // Check for Python projects
  if (fs.existsSync(pyprojectPath) || fs.existsSync(requirementsPath)) {
    return detectPythonProject(rootDir);
  }

  return {
    type: 'unknown',
    config: { rootDir }
  };
}

function detectNodeProject(packageJson: any, rootDir: string): DetectedProject {
  const deps = { ...packageJson.dependencies, ...packageJson.devDependencies };
  const scripts = packageJson.scripts || {};

  // Next.js
  if (deps['next']) {
    return {
      type: 'nextjs',
      config: {
        name: packageJson.name || 'nextjs-app',
        rootDir,
        buildCommand: scripts.build || 'npm run build',
        devCommand: scripts.dev || 'npm run dev',
        devUrl: 'http://localhost:3000',
        devPort: 3000,
        startupWaitMs: 5000,
        healthCheckPath: '/'
      }
    };
  }

  // Vite
  if (deps['vite']) {
    return {
      type: 'vite',
      config: {
        name: packageJson.name || 'vite-app',
        rootDir,
        buildCommand: scripts.build || 'npm run build',
        devCommand: scripts.dev || 'npm run dev',
        devUrl: 'http://localhost:5173',
        devPort: 5173,
        startupWaitMs: 3000,
        healthCheckPath: '/'
      }
    };
  }

  // Create React App
  if (deps['react-scripts']) {
    return {
      type: 'cra',
      config: {
        name: packageJson.name || 'cra-app',
        rootDir,
        buildCommand: scripts.build || 'npm run build',
        devCommand: scripts.start || 'npm start',
        devUrl: 'http://localhost:3000',
        devPort: 3000,
        startupWaitMs: 10000,
        healthCheckPath: '/'
      }
    };
  }

  // Remix
  if (deps['@remix-run/node'] || deps['@remix-run/react']) {
    return {
      type: 'remix',
      config: {
        name: packageJson.name || 'remix-app',
        rootDir,
        buildCommand: scripts.build || 'npm run build',
        devCommand: scripts.dev || 'npm run dev',
        devUrl: 'http://localhost:3000',
        devPort: 3000,
        startupWaitMs: 5000,
        healthCheckPath: '/'
      }
    };
  }

  // Express
  if (deps['express']) {
    const port = extractPortFromScripts(scripts) || 3000;
    return {
      type: 'express',
      config: {
        name: packageJson.name || 'express-app',
        rootDir,
        buildCommand: scripts.build || 'npm run build',
        devCommand: scripts.dev || scripts.start || 'npm start',
        devUrl: `http://localhost:${port}`,
        devPort: port,
        startupWaitMs: 3000,
        healthCheckPath: '/health'
      }
    };
  }

  // Fastify
  if (deps['fastify']) {
    const port = extractPortFromScripts(scripts) || 3000;
    return {
      type: 'fastify',
      config: {
        name: packageJson.name || 'fastify-app',
        rootDir,
        buildCommand: scripts.build || 'npm run build',
        devCommand: scripts.dev || scripts.start || 'npm start',
        devUrl: `http://localhost:${port}`,
        devPort: port,
        startupWaitMs: 3000,
        healthCheckPath: '/health'
      }
    };
  }

  // Unknown Node project
  return {
    type: 'unknown',
    config: {
      name: packageJson.name || 'node-app',
      rootDir,
      buildCommand: scripts.build,
      devCommand: scripts.dev || scripts.start,
      devUrl: 'http://localhost:3000',
      devPort: 3000,
      startupWaitMs: 5000
    }
  };
}

function detectPythonProject(rootDir: string): DetectedProject {
  const managePyPath = path.join(rootDir, 'manage.py');
  const appPyPath = path.join(rootDir, 'app.py');
  const mainPyPath = path.join(rootDir, 'main.py');

  // Django
  if (fs.existsSync(managePyPath)) {
    return {
      type: 'django',
      config: {
        name: path.basename(rootDir),
        rootDir,
        buildCommand: 'pip install -r requirements.txt',
        devCommand: 'python manage.py runserver',
        devUrl: 'http://localhost:8000',
        devPort: 8000,
        startupWaitMs: 5000,
        healthCheckPath: '/'
      }
    };
  }

  // Flask (check for app.py or main.py with Flask import)
  if (fs.existsSync(appPyPath) || fs.existsSync(mainPyPath)) {
    const checkFile = fs.existsSync(appPyPath) ? appPyPath : mainPyPath;
    const content = fs.readFileSync(checkFile, 'utf-8');
    if (content.includes('flask') || content.includes('Flask')) {
      return {
        type: 'flask',
        config: {
          name: path.basename(rootDir),
          rootDir,
          buildCommand: 'pip install -r requirements.txt',
          devCommand: fs.existsSync(appPyPath) ? 'flask run' : 'python main.py',
          devUrl: 'http://localhost:5000',
          devPort: 5000,
          startupWaitMs: 3000,
          healthCheckPath: '/'
        }
      };
    }
  }

  return {
    type: 'unknown',
    config: { rootDir }
  };
}

function extractPortFromScripts(scripts: Record<string, string>): number | null {
  const allScripts = Object.values(scripts).join(' ');
  const portMatch = allScripts.match(/(?:PORT=|--port[=\s])(\d+)/);
  return portMatch ? parseInt(portMatch[1], 10) : null;
}
