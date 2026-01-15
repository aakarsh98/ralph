#!/bin/bash
# Droid Ralph - Autonomous AI agent loop using Factory's Droid CLI
# Usage: ./droid-ralph.sh [max_iterations]

set -e

MAX_ITERATIONS=${1:-10}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PRD_FILE="$SCRIPT_DIR/prd.json"
PROGRESS_FILE="$SCRIPT_DIR/progress.txt"
PROMPT_FILE="$SCRIPT_DIR/droid-prompt.md"
ARCHIVE_DIR="$SCRIPT_DIR/archive"
LAST_BRANCH_FILE="$SCRIPT_DIR/.last-branch"

# Check if droid CLI is installed
if ! command -v droid &> /dev/null; then
    echo "Error: droid CLI is not installed."
    echo "Install it with: curl -fsSL https://app.factory.ai/cli | sh"
    exit 1
fi

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed."
    echo "Install it with: brew install jq (macOS) or apt-get install jq (Linux)"
    exit 1
fi

# Check if prd.json exists
if [ ! -f "$PRD_FILE" ]; then
    echo "Error: prd.json not found at $PRD_FILE"
    echo "Create a prd.json file with your user stories first."
    exit 1
fi

# Check if prompt file exists
if [ ! -f "$PROMPT_FILE" ]; then
    echo "Error: droid-prompt.md not found at $PROMPT_FILE"
    exit 1
fi

# Archive previous run if branch changed
if [ -f "$PRD_FILE" ] && [ -f "$LAST_BRANCH_FILE" ]; then
    CURRENT_BRANCH=$(jq -r '.branchName // empty' "$PRD_FILE" 2>/dev/null || echo "")
    LAST_BRANCH=$(cat "$LAST_BRANCH_FILE" 2>/dev/null || echo "")
    
    if [ -n "$CURRENT_BRANCH" ] && [ -n "$LAST_BRANCH" ] && [ "$CURRENT_BRANCH" != "$LAST_BRANCH" ]; then
        DATE=$(date +%Y-%m-%d)
        FOLDER_NAME=$(echo "$LAST_BRANCH" | sed 's|^feature/||' | sed 's|^ralph/||')
        ARCHIVE_FOLDER="$ARCHIVE_DIR/$DATE-$FOLDER_NAME"
        
        echo "Archiving previous run: $LAST_BRANCH"
        mkdir -p "$ARCHIVE_FOLDER"
        [ -f "$PRD_FILE" ] && cp "$PRD_FILE" "$ARCHIVE_FOLDER/"
        [ -f "$PROGRESS_FILE" ] && cp "$PROGRESS_FILE" "$ARCHIVE_FOLDER/"
        echo "   Archived to: $ARCHIVE_FOLDER"
        
        # Reset progress file for new run
        echo "# Droid Ralph Progress Log" > "$PROGRESS_FILE"
        echo "Started: $(date)" >> "$PROGRESS_FILE"
        echo "---" >> "$PROGRESS_FILE"
    fi
fi

# Track current branch
if [ -f "$PRD_FILE" ]; then
    CURRENT_BRANCH=$(jq -r '.branchName // empty' "$PRD_FILE" 2>/dev/null || echo "")
    if [ -n "$CURRENT_BRANCH" ]; then
        echo "$CURRENT_BRANCH" > "$LAST_BRANCH_FILE"
    fi
fi

# Initialize progress file if it doesn't exist
if [ ! -f "$PROGRESS_FILE" ]; then
    echo "# Droid Ralph Progress Log" > "$PROGRESS_FILE"
    echo "Started: $(date)" >> "$PROGRESS_FILE"
    echo "---" >> "$PROGRESS_FILE"
fi

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║           DROID RALPH - Autonomous Agent Loop             ║"
echo "╠═══════════════════════════════════════════════════════════╣"
echo "║  Max iterations: $MAX_ITERATIONS                                       ║"
echo "║  PRD: $PRD_FILE"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

for i in $(seq 1 $MAX_ITERATIONS); do
    echo ""
    echo "═══════════════════════════════════════════════════════════"
    echo "  Droid Ralph - Iteration $i of $MAX_ITERATIONS"
    echo "═══════════════════════════════════════════════════════════"
    echo ""
    
    # Check if all stories are complete before running
    REMAINING=$(jq '[.userStories[] | select(.passes == false)] | length' "$PRD_FILE" 2>/dev/null || echo "0")
    if [ "$REMAINING" -eq 0 ]; then
        echo ""
        echo "╔═══════════════════════════════════════════════════════════╗"
        echo "║              ALL STORIES COMPLETE!                        ║"
        echo "╠═══════════════════════════════════════════════════════════╣"
        echo "║  Completed at iteration $i of $MAX_ITERATIONS                            ║"
        echo "╚═══════════════════════════════════════════════════════════╝"
        exit 0
    fi
    
    echo "Stories remaining: $REMAINING"
    echo ""
    
    # Run droid exec with the prompt file
    # Using --auto high to allow file edits, git commits, and command execution
    OUTPUT=$(droid exec \
        --auto high \
        --cwd "$SCRIPT_DIR" \
        -f "$PROMPT_FILE" \
        --output-format text \
        2>&1 | tee /dev/stderr) || true
    
    # Check for completion signal
    if echo "$OUTPUT" | grep -q "ALL_STORIES_COMPLETE"; then
        echo ""
        echo "╔═══════════════════════════════════════════════════════════╗"
        echo "║              ALL STORIES COMPLETE!                        ║"
        echo "╠═══════════════════════════════════════════════════════════╣"
        echo "║  Droid Ralph finished all tasks!                          ║"
        echo "║  Completed at iteration $i of $MAX_ITERATIONS                            ║"
        echo "╚═══════════════════════════════════════════════════════════╝"
        exit 0
    fi
    
    # Also check prd.json directly
    REMAINING=$(jq '[.userStories[] | select(.passes == false)] | length' "$PRD_FILE" 2>/dev/null || echo "0")
    if [ "$REMAINING" -eq 0 ]; then
        echo ""
        echo "╔═══════════════════════════════════════════════════════════╗"
        echo "║              ALL STORIES COMPLETE!                        ║"
        echo "╠═══════════════════════════════════════════════════════════╣"
        echo "║  Droid Ralph finished all tasks!                          ║"
        echo "║  Completed at iteration $i of $MAX_ITERATIONS                            ║"
        echo "╚═══════════════════════════════════════════════════════════╝"
        exit 0
    fi
    
    echo ""
    echo "Iteration $i complete. Continuing to next iteration..."
    echo ""
    sleep 2
done

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║                 MAX ITERATIONS REACHED                    ║"
echo "╠═══════════════════════════════════════════════════════════╣"
echo "║  Droid Ralph reached $MAX_ITERATIONS iterations without completing.    ║"
echo "║  Check progress.txt for status.                           ║"
echo "╚═══════════════════════════════════════════════════════════╝"
exit 1
