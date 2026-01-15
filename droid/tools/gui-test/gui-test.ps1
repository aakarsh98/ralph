# GUI Test Runner for Ralph (Windows PowerShell) - Using UI-TARS
# Usage: .\gui-test.ps1 <prd.json> [story_id] [options]

param(
    [Parameter(Position=0)]
    [string]$PrdFile = ".\prd.json",
    
    [Parameter(Position=1)]
    [string]$StoryId = "",
    
    [switch]$NoHeadless,
    
    [string]$VlmProvider = $env:VLM_PROVIDER,
    [string]$VlmModel = $env:VLM_MODEL,
    [string]$VlmApiKey = $env:UI_TARS_API_KEY
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Set defaults - UI-TARS as default
if (-not $VlmProvider) { $VlmProvider = "ui-tars" }
if (-not $VlmModel) { $VlmModel = "ui-tars-1.5-7b" }

Write-Host ""
Write-Host "╔═══════════════════════════════════════════════════════════╗"
Write-Host "║              RALPH GUI TEST RUNNER                        ║"
Write-Host "╚═══════════════════════════════════════════════════════════╝"
Write-Host ""
Write-Host "PRD File: $PrdFile"
Write-Host "Story ID: $(if ($StoryId) { $StoryId } else { 'auto (first incomplete)' })"
Write-Host "Headless: $(-not $NoHeadless)"
Write-Host "VLM Provider: $VlmProvider"
Write-Host "VLM Model: $VlmModel"
Write-Host ""

# Check if PRD file exists
if (-not (Test-Path $PrdFile)) {
    Write-Error "PRD file not found: $PrdFile"
    exit 1
}

# Check for node_modules, install if needed
if (-not (Test-Path "$ScriptDir\node_modules")) {
    Write-Host "Installing dependencies..."
    Push-Location $ScriptDir
    npm install
    Pop-Location
}

# Build TypeScript if needed
if (-not (Test-Path "$ScriptDir\dist")) {
    Write-Host "Building TypeScript..."
    Push-Location $ScriptDir
    npm run build
    Pop-Location
}

# Build arguments
$Args = @($PrdFile)
if ($StoryId) { $Args += @("--story", $StoryId) }
if ($NoHeadless) { $Args += "--no-headless" }
if ($VlmProvider) { $Args += @("--vlm-provider", $VlmProvider) }
if ($VlmModel) { $Args += @("--vlm-model", $VlmModel) }
if ($VlmApiKey) { $Args += @("--vlm-api-key", $VlmApiKey) }

# Run the test runner
node "$ScriptDir\dist\test-runner.js" @Args
