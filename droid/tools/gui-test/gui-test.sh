#!/bin/bash
# GUI Test Runner for Ralph (using UI-TARS)
# Usage: ./gui-test.sh <prd.json> [story_id] [options]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PRD_FILE="${1:-./prd.json}"
STORY_ID="${2:-}"

# Parse options - Default to UI-TARS
HEADLESS="true"
VLM_PROVIDER="${VLM_PROVIDER:-ui-tars}"
VLM_MODEL="${VLM_MODEL:-ui-tars-1.5-7b}"

for arg in "$@"; do
    case $arg in
        --no-headless)
            HEADLESS="false"
            ;;
        --vlm-provider=*)
            VLM_PROVIDER="${arg#*=}"
            ;;
        --vlm-model=*)
            VLM_MODEL="${arg#*=}"
            ;;
    esac
done

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║              RALPH GUI TEST RUNNER                        ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""
echo "PRD File: $PRD_FILE"
echo "Story ID: ${STORY_ID:-auto (first incomplete)}"
echo "Headless: $HEADLESS"
echo "VLM Provider: $VLM_PROVIDER"
echo "VLM Model: $VLM_MODEL"
echo ""

# Check if PRD file exists
if [ ! -f "$PRD_FILE" ]; then
    echo "Error: PRD file not found: $PRD_FILE"
    exit 1
fi

# Check for node_modules, install if needed
if [ ! -d "$SCRIPT_DIR/node_modules" ]; then
    echo "Installing dependencies..."
    cd "$SCRIPT_DIR"
    npm install
    cd - > /dev/null
fi

# Build TypeScript if needed
if [ ! -d "$SCRIPT_DIR/dist" ]; then
    echo "Building TypeScript..."
    cd "$SCRIPT_DIR"
    npm run build
    cd - > /dev/null
fi

# Run the test runner
ARGS="$PRD_FILE"
[ -n "$STORY_ID" ] && ARGS="$ARGS --story $STORY_ID"
[ "$HEADLESS" = "false" ] && ARGS="$ARGS --no-headless"
[ -n "$VLM_PROVIDER" ] && ARGS="$ARGS --vlm-provider $VLM_PROVIDER"
[ -n "$VLM_MODEL" ] && ARGS="$ARGS --vlm-model $VLM_MODEL"

node "$SCRIPT_DIR/dist/test-runner.js" $ARGS
