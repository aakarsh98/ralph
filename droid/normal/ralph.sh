#!/bin/bash
# Droid Ralph - NORMAL MODE (Trust-based verification)
# Usage: ./ralph.sh [max_iterations]

set -e

MODE="NORMAL"
MAX_ITERATIONS=${1:-10}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PRD_FILE="$SCRIPT_DIR/prd.json"
PROGRESS_FILE="$SCRIPT_DIR/progress.txt"
PROMPT_FILE="$SCRIPT_DIR/prompt.md"
METRICS_FILE="$SCRIPT_DIR/metrics.json"

# Check dependencies
command -v droid &> /dev/null || { echo "Error: droid CLI not installed"; exit 1; }
command -v jq &> /dev/null || { echo "Error: jq not installed"; exit 1; }
[ -f "$PRD_FILE" ] || { echo "Error: prd.json not found"; exit 1; }
[ -f "$PROMPT_FILE" ] || { echo "Error: prompt.md not found"; exit 1; }

# Initialize metrics
START_TIME=$(date +%s)
TOTAL_ITERATIONS=0
STORIES_COMPLETED=0

# Initialize progress file
if [ ! -f "$PROGRESS_FILE" ]; then
    cat > "$PROGRESS_FILE" << EOF
# Droid Ralph Progress Log - NORMAL MODE
Started: $(date)
---
EOF
fi

# Initialize metrics file
cat > "$METRICS_FILE" << EOF
{
  "mode": "normal",
  "startTime": "$(date -Iseconds)",
  "iterations": []
}
EOF

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║        DROID RALPH - NORMAL MODE (Trust-based)            ║"
echo "╠═══════════════════════════════════════════════════════════╣"
echo "║  Max iterations: $MAX_ITERATIONS                                       ║"
echo "║  Verification: Quality checks only                        ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

for i in $(seq 1 $MAX_ITERATIONS); do
    ITER_START=$(date +%s)
    
    echo ""
    echo "═══════════════════════════════════════════════════════════"
    echo "  [$MODE] Iteration $i of $MAX_ITERATIONS"
    echo "═══════════════════════════════════════════════════════════"
    
    REMAINING=$(jq '[.userStories[] | select(.passes == false)] | length' "$PRD_FILE" 2>/dev/null || echo "0")
    
    if [ "$REMAINING" -eq 0 ]; then
        break
    fi
    
    CURRENT_STORY=$(jq -r '[.userStories[] | select(.passes == false)] | sort_by(.priority) | .[0].id // "none"' "$PRD_FILE")
    echo "Working on: $CURRENT_STORY"
    echo "Remaining: $REMAINING stories"
    echo ""
    
    # Run droid exec with JSON output to capture metrics
    ITER_OUTPUT=$(droid exec \
        --auto high \
        --cwd "$SCRIPT_DIR" \
        -f "$PROMPT_FILE" \
        --output-format json \
        2>&1) || true
    
    ITER_END=$(date +%s)
    ITER_DURATION=$((ITER_END - ITER_START))
    TOTAL_ITERATIONS=$((TOTAL_ITERATIONS + 1))
    
    # Extract metrics from JSON output
    DURATION_MS=$(echo "$ITER_OUTPUT" | jq -r '.duration_ms // 0' 2>/dev/null || echo "0")
    NUM_TURNS=$(echo "$ITER_OUTPUT" | jq -r '.num_turns // 0' 2>/dev/null || echo "0")
    
    # Check if story was completed
    NEW_REMAINING=$(jq '[.userStories[] | select(.passes == false)] | length' "$PRD_FILE" 2>/dev/null || echo "0")
    if [ "$NEW_REMAINING" -lt "$REMAINING" ]; then
        STORIES_COMPLETED=$((STORIES_COMPLETED + 1))
        STATUS="completed"
    else
        STATUS="incomplete"
    fi
    
    # Update metrics file
    jq --arg iter "$i" \
       --arg story "$CURRENT_STORY" \
       --arg status "$STATUS" \
       --arg duration "$ITER_DURATION" \
       --arg duration_ms "$DURATION_MS" \
       --arg turns "$NUM_TURNS" \
       '.iterations += [{
         "iteration": ($iter | tonumber),
         "story": $story,
         "status": $status,
         "duration_seconds": ($duration | tonumber),
         "duration_ms": ($duration_ms | tonumber),
         "turns": ($turns | tonumber)
       }]' "$METRICS_FILE" > "$METRICS_FILE.tmp" && mv "$METRICS_FILE.tmp" "$METRICS_FILE"
    
    echo ""
    echo "Iteration $i: $STATUS (${ITER_DURATION}s, $NUM_TURNS turns)"
    
    # Check completion
    if echo "$ITER_OUTPUT" | jq -r '.result // ""' 2>/dev/null | grep -q "ALL_STORIES_COMPLETE"; then
        break
    fi
    
    if [ "$NEW_REMAINING" -eq 0 ]; then
        break
    fi
    
    sleep 2
done

# Final metrics
END_TIME=$(date +%s)
TOTAL_DURATION=$((END_TIME - START_TIME))
FINAL_REMAINING=$(jq '[.userStories[] | select(.passes == false)] | length' "$PRD_FILE" 2>/dev/null || echo "0")
TOTAL_STORIES=$(jq '.userStories | length' "$PRD_FILE" 2>/dev/null || echo "0")

# Update final metrics
jq --arg endTime "$(date -Iseconds)" \
   --arg totalDuration "$TOTAL_DURATION" \
   --arg totalIterations "$TOTAL_ITERATIONS" \
   --arg storiesCompleted "$STORIES_COMPLETED" \
   --arg totalStories "$TOTAL_STORIES" \
   --arg remaining "$FINAL_REMAINING" \
   '. + {
     "endTime": $endTime,
     "totalDurationSeconds": ($totalDuration | tonumber),
     "totalIterations": ($totalIterations | tonumber),
     "storiesCompleted": ($storiesCompleted | tonumber),
     "totalStories": ($totalStories | tonumber),
     "storiesRemaining": ($remaining | tonumber),
     "successRate": (if ($totalStories | tonumber) > 0 then (($storiesCompleted | tonumber) / ($totalStories | tonumber) * 100) else 0 end)
   }' "$METRICS_FILE" > "$METRICS_FILE.tmp" && mv "$METRICS_FILE.tmp" "$METRICS_FILE"

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║              NORMAL MODE - FINAL RESULTS                  ║"
echo "╠═══════════════════════════════════════════════════════════╣"
printf "║  Stories completed: %-3s / %-3s                            ║\n" "$STORIES_COMPLETED" "$TOTAL_STORIES"
printf "║  Total iterations:  %-3s                                   ║\n" "$TOTAL_ITERATIONS"
printf "║  Total time:        %-4ss                                 ║\n" "$TOTAL_DURATION"
printf "║  Avg per story:     %-4ss                                 ║\n" "$((TOTAL_DURATION / (STORIES_COMPLETED + 1)))"
echo "║  Metrics saved to:  metrics.json                          ║"
echo "╚═══════════════════════════════════════════════════════════╝"

[ "$FINAL_REMAINING" -eq 0 ] && exit 0 || exit 1
