#═══════════════════════════════════════════════════════════════════════════════
# Ralph GUI Test Runner (UI-TARS Powered) - Windows PowerShell
# 
# All-in-one script for running GUI/Browser tests with UI-TARS
# Includes: dependency installation, build, dev server, and test execution
#
# Usage:
#   .\run-gui-test.ps1 <prd.json> [story_id] [options]
#
# Examples:
#   .\run-gui-test.ps1 .\prd.json
#   .\run-gui-test.ps1 .\prd.json US-002 -NoHeadless
#   .\run-gui-test.ps1 .\prd.json -Provider volcengine
#═══════════════════════════════════════════════════════════════════════════════

param(
    [Parameter(Position=0)]
    [string]$PrdFile = ".\prd.json",
    
    [Parameter(Position=1)]
    [string]$StoryId = "",
    
    [switch]$NoHeadless,
    [switch]$BrowserOnly,
    [switch]$SkipInstall,
    [switch]$SkipBuild,
    
    [ValidateSet("ui-tars", "agent-tars", "volcengine", "huggingface", "openai", "anthropic")]
    [string]$Provider = "ui-tars",
    
    [string]$Model = "",
    [string]$ApiKey = "",
    [string]$BaseUrl = ""
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

#───────────────────────────────────────────────────────────────────────────────
# Configuration Defaults
#───────────────────────────────────────────────────────────────────────────────

# UI-TARS defaults
$UITarsDefaults = @{
    "ui-tars" = @{
        Model = "ui-tars-1.5-7b"
        BaseUrl = $env:UI_TARS_BASE_URL
        ApiKey = $env:UI_TARS_API_KEY
    }
    "volcengine" = @{
        Model = "doubao-1-5-ui-tars-250328"
        BaseUrl = "https://ark.cn-beijing.volces.com/api/v3"
        ApiKey = $env:VOLCENGINE_API_KEY
    }
    "huggingface" = @{
        Model = "ByteDance-Seed/UI-TARS-1.5-7B"
        BaseUrl = $env:HUGGINGFACE_BASE_URL
        ApiKey = $env:HUGGINGFACE_API_KEY
    }
    "agent-tars" = @{
        Model = "doubao-1-5-thinking-vision-pro-250428"
        BaseUrl = ""
        ApiKey = $env:UI_TARS_API_KEY
    }
}

#───────────────────────────────────────────────────────────────────────────────
# Auto-detect Configuration
#───────────────────────────────────────────────────────────────────────────────

function Get-ApiConfig {
    $defaults = $UITarsDefaults[$Provider]
    
    $script:FinalModel = if ($Model) { $Model } else { $defaults.Model }
    $script:FinalBaseUrl = if ($BaseUrl) { $BaseUrl } else { $defaults.BaseUrl }
    $script:FinalApiKey = if ($ApiKey) { $ApiKey } elseif ($defaults.ApiKey) { $defaults.ApiKey } else { $env:VLM_API_KEY }
}

#───────────────────────────────────────────────────────────────────────────────
# Display Banner
#───────────────────────────────────────────────────────────────────────────────

function Show-Banner {
    Write-Host ""
    Write-Host "╔═══════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║          RALPH GUI TEST RUNNER (UI-TARS POWERED)                      ║" -ForegroundColor Cyan
    Write-Host "╠═══════════════════════════════════════════════════════════════════════╣" -ForegroundColor Cyan
    Write-Host "║  PRD File:     $PrdFile" -ForegroundColor White
    Write-Host "║  Story ID:     $(if ($StoryId) { $StoryId } else { 'auto (first incomplete)' })" -ForegroundColor White
    Write-Host "║  Provider:     $Provider" -ForegroundColor White
    Write-Host "║  Model:        $FinalModel" -ForegroundColor White
    Write-Host "║  Headless:     $(-not $NoHeadless)" -ForegroundColor White
    Write-Host "║  Browser Only: $BrowserOnly" -ForegroundColor White
    Write-Host "╚═══════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

#───────────────────────────────────────────────────────────────────────────────
# Check Prerequisites
#───────────────────────────────────────────────────────────────────────────────

function Test-Prerequisites {
    Write-Host "[Setup] Checking prerequisites..." -ForegroundColor Yellow

    # Check Node.js
    try {
        $nodeVersion = node --version
        Write-Host "  ✓ Node.js $nodeVersion" -ForegroundColor Green
    } catch {
        Write-Host "ERROR: Node.js is not installed." -ForegroundColor Red
        Write-Host "Install from: https://nodejs.org/" -ForegroundColor Red
        exit 1
    }

    # Check PRD file
    if (-not (Test-Path $PrdFile)) {
        Write-Host "ERROR: PRD file not found: $PrdFile" -ForegroundColor Red
        exit 1
    }
    Write-Host "  ✓ PRD file exists" -ForegroundColor Green

    # Check API key
    if (-not $BrowserOnly -and -not $FinalApiKey) {
        Write-Host ""
        Write-Host "WARNING: No API key found for UI-TARS visual tests." -ForegroundColor Yellow
        Write-Host "Set one of these environment variables:" -ForegroundColor Yellow
        Write-Host "  - UI_TARS_API_KEY (for self-hosted UI-TARS)" -ForegroundColor Yellow
        Write-Host "  - VOLCENGINE_API_KEY (for ByteDance cloud)" -ForegroundColor Yellow
        Write-Host "  - VLM_API_KEY (generic fallback)" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Continuing with browser tests only..." -ForegroundColor Yellow
        $script:BrowserOnly = $true
    } else {
        Write-Host "  ✓ API key configured" -ForegroundColor Green
    }

    Write-Host ""
}

#───────────────────────────────────────────────────────────────────────────────
# Install Dependencies
#───────────────────────────────────────────────────────────────────────────────

function Install-Dependencies {
    if ($SkipInstall) {
        Write-Host "[Setup] Skipping dependency installation (-SkipInstall)" -ForegroundColor Gray
        return
    }

    if (-not (Test-Path "$ScriptDir\node_modules")) {
        Write-Host "[Setup] Installing dependencies..." -ForegroundColor Yellow
        Push-Location $ScriptDir
        npm install
        Pop-Location
        Write-Host "  ✓ Dependencies installed" -ForegroundColor Green
    } else {
        Write-Host "[Setup] Dependencies already installed" -ForegroundColor Gray
    }
}

#───────────────────────────────────────────────────────────────────────────────
# Build TypeScript
#───────────────────────────────────────────────────────────────────────────────

function Build-TypeScript {
    if ($SkipBuild) {
        Write-Host "[Setup] Skipping TypeScript build (-SkipBuild)" -ForegroundColor Gray
        return
    }

    if (-not (Test-Path "$ScriptDir\dist")) {
        Write-Host "[Setup] Building TypeScript..." -ForegroundColor Yellow
        Push-Location $ScriptDir
        npm run build
        Pop-Location
        Write-Host "  ✓ TypeScript built" -ForegroundColor Green
    } else {
        Write-Host "[Setup] TypeScript already built" -ForegroundColor Gray
    }
}

#───────────────────────────────────────────────────────────────────────────────
# Run Tests
#───────────────────────────────────────────────────────────────────────────────

function Start-Tests {
    Write-Host ""
    Write-Host "[Test] Starting test execution..." -ForegroundColor Yellow
    Write-Host ""

    # Build arguments
    $Args = @($PrdFile)
    
    if ($StoryId) { $Args += @("--story", $StoryId) }
    if ($NoHeadless) { $Args += "--no-headless" }
    if ($Provider) { $Args += @("--vlm-provider", $Provider) }
    if ($FinalModel) { $Args += @("--vlm-model", $FinalModel) }
    if ($FinalApiKey) { $Args += @("--vlm-api-key", $FinalApiKey) }
    if ($FinalBaseUrl) { $Args += @("--vlm-base-url", $FinalBaseUrl) }

    # Set environment variables
    $env:UI_TARS_API_KEY = $FinalApiKey
    $env:UI_TARS_BASE_URL = $FinalBaseUrl
    $env:VLM_API_KEY = $FinalApiKey

    # Run test runner
    node "$ScriptDir\dist\test-runner.js" @Args
}

#───────────────────────────────────────────────────────────────────────────────
# Main Execution
#───────────────────────────────────────────────────────────────────────────────

Get-ApiConfig
Show-Banner
Test-Prerequisites
Install-Dependencies
Build-TypeScript
Start-Tests
