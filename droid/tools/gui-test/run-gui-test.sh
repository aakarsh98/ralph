#!/bin/bash
#═══════════════════════════════════════════════════════════════════════════════
# Ralph GUI Test Runner (UI-TARS Powered)
# 
# All-in-one script for running GUI/Browser tests with UI-TARS
# Includes: dependency installation, build, dev server, and test execution
#
# Usage:
#   ./run-gui-test.sh <prd.json> [story_id] [options]
#
# Options:
#   --no-headless       Show browser window
#   --provider=X        ui-tars|agent-tars|volcengine|huggingface
#   --skip-install      Skip npm install
#   --skip-build        Skip TypeScript build
#   --browser-only      Run only browser tests (no VLM)
#
# Examples:
#   ./run-gui-test.sh ./prd.json
#   ./run-gui-test.sh ./prd.json US-002 --no-headless
#   ./run-gui-test.sh ./prd.json --provider=volcengine
#═══════════════════════════════════════════════════════════════════════════════

set -e

#───────────────────────────────────────────────────────────────────────────────
# Configuration Defaults (UI-TARS)
#───────────────────────────────────────────────────────────────────────────────

# Script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# UI-TARS Model Configuration
: "${UI_TARS_PROVIDER:=ui-tars}"
: "${UI_TARS_MODEL:=ui-tars-1.5-7b}"
: "${UI_TARS_BASE_URL:=}"
: "${UI_TARS_API_KEY:=}"

# Alternative: VolcEngine (ByteDance Cloud)
: "${VOLCENGINE_API_KEY:=}"
: "${VOLCENGINE_BASE_URL:=https://ark.cn-beijing.volces.com/api/v3}"
: "${VOLCENGINE_MODEL:=doubao-1-5-ui-tars-250328}"

# Alternative: Hugging Face
: "${HUGGINGFACE_API_KEY:=}"
: "${HUGGINGFACE_BASE_URL:=}"
: "${HUGGINGFACE_MODEL:=ByteDance-Seed/UI-TARS-1.5-7B}"

# Browser settings
HEADLESS="true"
BROWSER_ONLY="false"
SKIP_INSTALL="false"
SKIP_BUILD="false"

# PRD and story
PRD_FILE=""
STORY_ID=""

#───────────────────────────────────────────────────────────────────────────────
# Parse Arguments
#───────────────────────────────────────────────────────────────────────────────

for arg in "$@"; do
    case $arg in
        --no-headless)
            HEADLESS="false"
            ;;
        --browser-only)
            BROWSER_ONLY="true"
            ;;
        --skip-install)
            SKIP_INSTALL="true"
            ;;
        --skip-build)
            SKIP_BUILD="true"
            ;;
        --provider=*)
            UI_TARS_PROVIDER="${arg#*=}"
            ;;
        --model=*)
            UI_TARS_MODEL="${arg#*=}"
            ;;
        --api-key=*)
            UI_TARS_API_KEY="${arg#*=}"
            ;;
        --base-url=*)
            UI_TARS_BASE_URL="${arg#*=}"
            ;;
        -*)
            echo "Unknown option: $arg"
            ;;
        *)
            # Positional args: first is PRD, second is story ID
            if [ -z "$PRD_FILE" ]; then
                PRD_FILE="$arg"
            elif [ -z "$STORY_ID" ]; then
                STORY_ID="$arg"
            fi
            ;;
    esac
done

# Default PRD file
PRD_FILE="${PRD_FILE:-./prd.json}"

#───────────────────────────────────────────────────────────────────────────────
# Auto-detect API Key based on provider
#───────────────────────────────────────────────────────────────────────────────

detect_api_config() {
    case $UI_TARS_PROVIDER in
        ui-tars)
            API_KEY="${UI_TARS_API_KEY:-$VLM_API_KEY}"
            BASE_URL="${UI_TARS_BASE_URL}"
            MODEL="${UI_TARS_MODEL:-ui-tars-1.5-7b}"
            ;;
        volcengine)
            API_KEY="${VOLCENGINE_API_KEY:-$VLM_API_KEY}"
            BASE_URL="${VOLCENGINE_BASE_URL}"
            MODEL="${VOLCENGINE_MODEL}"
            ;;
        huggingface)
            API_KEY="${HUGGINGFACE_API_KEY:-$HF_TOKEN:-$VLM_API_KEY}"
            BASE_URL="${HUGGINGFACE_BASE_URL}"
            MODEL="${HUGGINGFACE_MODEL}"
            ;;
        agent-tars)
            API_KEY="${UI_TARS_API_KEY:-$VOLCENGINE_API_KEY:-$VLM_API_KEY}"
            BASE_URL=""
            MODEL="${UI_TARS_MODEL:-doubao-1-5-thinking-vision-pro-250428}"
            ;;
        *)
            API_KEY="${VLM_API_KEY}"
            BASE_URL="${VLM_BASE_URL}"
            MODEL="${VLM_MODEL:-gpt-4o}"
            ;;
    esac
}

#───────────────────────────────────────────────────────────────────────────────
# Display Banner
#───────────────────────────────────────────────────────────────────────────────

show_banner() {
    echo ""
    echo "╔═══════════════════════════════════════════════════════════════════════╗"
    echo "║          RALPH GUI TEST RUNNER (UI-TARS POWERED)                      ║"
    echo "╠═══════════════════════════════════════════════════════════════════════╣"
    echo "║  PRD File:    $PRD_FILE"
    echo "║  Story ID:    ${STORY_ID:-auto (first incomplete)}"
    echo "║  Provider:    $UI_TARS_PROVIDER"
    echo "║  Model:       $MODEL"
    echo "║  Headless:    $HEADLESS"
    echo "║  Browser Only: $BROWSER_ONLY"
    echo "╚═══════════════════════════════════════════════════════════════════════╝"
    echo ""
}

#───────────────────────────────────────────────────────────────────────────────
# Check Prerequisites
#───────────────────────────────────────────────────────────────────────────────

check_prerequisites() {
    echo "[Setup] Checking prerequisites..."

    # Check Node.js
    if ! command -v node &> /dev/null; then
        echo "ERROR: Node.js is not installed."
        echo "Install from: https://nodejs.org/"
        exit 1
    fi
    echo "  ✓ Node.js $(node --version)"

    # Check npm
    if ! command -v npm &> /dev/null; then
        echo "ERROR: npm is not installed."
        exit 1
    fi
    echo "  ✓ npm $(npm --version)"

    # Check PRD file exists
    if [ ! -f "$PRD_FILE" ]; then
        echo "ERROR: PRD file not found: $PRD_FILE"
        exit 1
    fi
    echo "  ✓ PRD file exists"

    # Check API key for GUI tests
    if [ "$BROWSER_ONLY" = "false" ] && [ -z "$API_KEY" ]; then
        echo ""
        echo "WARNING: No API key found for UI-TARS visual tests."
        echo "Set one of these environment variables:"
        echo "  - UI_TARS_API_KEY (for self-hosted UI-TARS)"
        echo "  - VOLCENGINE_API_KEY (for ByteDance cloud)"
        echo "  - HUGGINGFACE_API_KEY (for HuggingFace)"
        echo "  - VLM_API_KEY (generic fallback)"
        echo ""
        echo "Continuing with browser tests only..."
        BROWSER_ONLY="true"
    else
        echo "  ✓ API key configured"
    fi

    echo ""
}

#───────────────────────────────────────────────────────────────────────────────
# Install Dependencies
#───────────────────────────────────────────────────────────────────────────────

install_dependencies() {
    if [ "$SKIP_INSTALL" = "true" ]; then
        echo "[Setup] Skipping dependency installation (--skip-install)"
        return
    fi

    if [ ! -d "$SCRIPT_DIR/node_modules" ]; then
        echo "[Setup] Installing dependencies..."
        cd "$SCRIPT_DIR"
        npm install
        cd - > /dev/null
        echo "  ✓ Dependencies installed"
    else
        echo "[Setup] Dependencies already installed"
    fi
}

#───────────────────────────────────────────────────────────────────────────────
# Build TypeScript
#───────────────────────────────────────────────────────────────────────────────

build_typescript() {
    if [ "$SKIP_BUILD" = "true" ]; then
        echo "[Setup] Skipping TypeScript build (--skip-build)"
        return
    fi

    if [ ! -d "$SCRIPT_DIR/dist" ] || [ "$SCRIPT_DIR/src" -nt "$SCRIPT_DIR/dist" ]; then
        echo "[Setup] Building TypeScript..."
        cd "$SCRIPT_DIR"
        npm run build
        cd - > /dev/null
        echo "  ✓ TypeScript built"
    else
        echo "[Setup] TypeScript already built"
    fi
}

#───────────────────────────────────────────────────────────────────────────────
# Run Tests
#───────────────────────────────────────────────────────────────────────────────

run_tests() {
    echo ""
    echo "[Test] Starting test execution..."
    echo ""

    # Build command arguments
    local ARGS=("$PRD_FILE")
    
    [ -n "$STORY_ID" ] && ARGS+=("--story" "$STORY_ID")
    [ "$HEADLESS" = "false" ] && ARGS+=("--no-headless")
    [ -n "$UI_TARS_PROVIDER" ] && ARGS+=("--vlm-provider" "$UI_TARS_PROVIDER")
    [ -n "$MODEL" ] && ARGS+=("--vlm-model" "$MODEL")
    [ -n "$API_KEY" ] && ARGS+=("--vlm-api-key" "$API_KEY")
    [ -n "$BASE_URL" ] && ARGS+=("--vlm-base-url" "$BASE_URL")

    # Export for Node process
    export UI_TARS_API_KEY="$API_KEY"
    export UI_TARS_BASE_URL="$BASE_URL"
    export VLM_API_KEY="$API_KEY"

    # Run the test runner
    node "$SCRIPT_DIR/dist/test-runner.js" "${ARGS[@]}"
}

#───────────────────────────────────────────────────────────────────────────────
# Main Execution
#───────────────────────────────────────────────────────────────────────────────

main() {
    detect_api_config
    show_banner
    check_prerequisites
    install_dependencies
    build_typescript
    run_tests
}

# Run main
main
