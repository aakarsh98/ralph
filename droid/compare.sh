#!/bin/bash
# Compare Normal vs Strict mode performance
# Usage: ./compare.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NORMAL_DIR="$SCRIPT_DIR/normal"
STRICT_DIR="$SCRIPT_DIR/strict"
RESULTS_FILE="$SCRIPT_DIR/comparison-results.md"

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║         DROID RALPH - MODE COMPARISON                     ║"
echo "╠═══════════════════════════════════════════════════════════╣"
echo "║  This will run both NORMAL and STRICT modes sequentially  ║"
echo "║  and compare their performance metrics.                   ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# Check if both directories have required files
[ -f "$NORMAL_DIR/ralph.sh" ] || { echo "Error: normal/ralph.sh not found"; exit 1; }
[ -f "$STRICT_DIR/ralph.sh" ] || { echo "Error: strict/ralph.sh not found"; exit 1; }

# Reset PRDs to initial state
echo "Resetting PRD files..."
for dir in "$NORMAL_DIR" "$STRICT_DIR"; do
    if [ -f "$dir/prd.json" ]; then
        # Reset all passes to false
        jq '.userStories = [.userStories[] | .passes = false | .notes = ""]' "$dir/prd.json" > "$dir/prd.json.tmp"
        mv "$dir/prd.json.tmp" "$dir/prd.json"
    fi
    # Clear progress files
    rm -f "$dir/progress.txt"
    rm -f "$dir/metrics.json"
    # Clear src directory if exists
    rm -rf "$dir/src"
done

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  PHASE 1: Running NORMAL mode..."
echo "═══════════════════════════════════════════════════════════"
echo ""

cd "$NORMAL_DIR"
chmod +x ralph.sh
./ralph.sh 10 || true

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  PHASE 2: Running STRICT mode..."
echo "═══════════════════════════════════════════════════════════"
echo ""

cd "$STRICT_DIR"
chmod +x ralph.sh
./ralph.sh 10 || true

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  PHASE 3: Comparing results..."
echo "═══════════════════════════════════════════════════════════"
echo ""

# Generate comparison report
cat > "$RESULTS_FILE" << 'EOF'
# Droid Ralph Mode Comparison Results

Generated: $(date)

## Summary

EOF

# Extract metrics from both
NORMAL_METRICS="$NORMAL_DIR/metrics.json"
STRICT_METRICS="$STRICT_DIR/metrics.json"

if [ -f "$NORMAL_METRICS" ] && [ -f "$STRICT_METRICS" ]; then
    # Normal mode stats
    N_COMPLETED=$(jq -r '.storiesCompleted // 0' "$NORMAL_METRICS")
    N_TOTAL=$(jq -r '.totalStories // 0' "$NORMAL_METRICS")
    N_ITERATIONS=$(jq -r '.totalIterations // 0' "$NORMAL_METRICS")
    N_DURATION=$(jq -r '.totalDurationSeconds // 0' "$NORMAL_METRICS")
    N_SUCCESS=$(jq -r '.successRate // 0' "$NORMAL_METRICS")
    
    # Strict mode stats
    S_COMPLETED=$(jq -r '.storiesCompleted // 0' "$STRICT_METRICS")
    S_TOTAL=$(jq -r '.totalStories // 0' "$STRICT_METRICS")
    S_ITERATIONS=$(jq -r '.totalIterations // 0' "$STRICT_METRICS")
    S_DURATION=$(jq -r '.totalDurationSeconds // 0' "$STRICT_METRICS")
    S_SUCCESS=$(jq -r '.successRate // 0' "$STRICT_METRICS")
    
    cat >> "$RESULTS_FILE" << EOF

| Metric | Normal Mode | Strict Mode | Winner |
|--------|-------------|-------------|--------|
| Stories Completed | $N_COMPLETED / $N_TOTAL | $S_COMPLETED / $S_TOTAL | $([ "$N_COMPLETED" -ge "$S_COMPLETED" ] && echo "Normal" || echo "Strict") |
| Total Iterations | $N_ITERATIONS | $S_ITERATIONS | $([ "$N_ITERATIONS" -le "$S_ITERATIONS" ] && echo "Normal" || echo "Strict") |
| Total Time (s) | $N_DURATION | $S_DURATION | $([ "$N_DURATION" -le "$S_DURATION" ] && echo "Normal" || echo "Strict") |
| Success Rate | ${N_SUCCESS}% | ${S_SUCCESS}% | $(echo "$N_SUCCESS >= $S_SUCCESS" | bc -l | grep -q 1 && echo "Normal" || echo "Strict") |

## Iteration Details

### Normal Mode
\`\`\`json
$(cat "$NORMAL_METRICS" | jq '.iterations')
\`\`\`

### Strict Mode
\`\`\`json
$(cat "$STRICT_METRICS" | jq '.iterations')
\`\`\`

## Analysis

- **Normal Mode**: Faster but relies on trust-based verification
- **Strict Mode**: Slower but provides evidence-based verification

## Raw Metrics

### Normal Mode (metrics.json)
\`\`\`json
$(cat "$NORMAL_METRICS")
\`\`\`

### Strict Mode (metrics.json)
\`\`\`json
$(cat "$STRICT_METRICS")
\`\`\`
EOF

    echo ""
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║                  COMPARISON RESULTS                       ║"
    echo "╠═══════════════════════════════════════════════════════════╣"
    echo "║                   NORMAL    │    STRICT                   ║"
    echo "╠═══════════════════════════════════════════════════════════╣"
    printf "║  Stories:         %-3s/%-3s   │    %-3s/%-3s                   ║\n" "$N_COMPLETED" "$N_TOTAL" "$S_COMPLETED" "$S_TOTAL"
    printf "║  Iterations:      %-3s       │    %-3s                       ║\n" "$N_ITERATIONS" "$S_ITERATIONS"
    printf "║  Duration:        %-4ss     │    %-4ss                     ║\n" "$N_DURATION" "$S_DURATION"
    printf "║  Success:         %-3s%%      │    %-3s%%                      ║\n" "$N_SUCCESS" "$S_SUCCESS"
    echo "╠═══════════════════════════════════════════════════════════╣"
    echo "║  Full report: comparison-results.md                       ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
else
    echo "Error: Could not find metrics files"
    echo "Normal: $NORMAL_METRICS exists: $([ -f "$NORMAL_METRICS" ] && echo "yes" || echo "no")"
    echo "Strict: $STRICT_METRICS exists: $([ -f "$STRICT_METRICS" ] && echo "yes" || echo "no")"
fi
