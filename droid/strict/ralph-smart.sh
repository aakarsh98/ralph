#!/bin/bash
# Droid Ralph - STRICT MODE with INTELLIGENT MODEL SELECTION
# Selects optimal model based on task complexity
# Usage: ./ralph-smart.sh [max_iterations]

set -e

MODE="STRICT-SMART"
MAX_ITERATIONS=${1:-10}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PRD_FILE="$SCRIPT_DIR/prd.json"
PROGRESS_FILE="$SCRIPT_DIR/progress.txt"
PROMPT_FILE="$SCRIPT_DIR/prompt.md"
METRICS_FILE="$SCRIPT_DIR/metrics.json"
MODELS_FILE="$SCRIPT_DIR/../models/MODELS.json"

# Model definitions based on research (SWE-bench, Vellum, Anthropic, OpenAI)
# See MODEL-RESEARCH.md for full citations

declare -A MODEL_TIERS
MODEL_TIERS["trivial"]="gemini-3-flash-preview"      # 0.2× - best budget (76.2% SWE-bench)
MODEL_TIERS["simple"]="gpt-5.1-codex"                # 0.5× - fast code gen (GitHub docs)
MODEL_TIERS["moderate"]="gpt-5.1-codex"              # 0.5× - good balance
MODEL_TIERS["complex"]="claude-sonnet-4-5-20250929"  # 1.2× - 82% SWE-bench leader
MODEL_TIERS["critical"]="claude-opus-4-5-20251101"   # 2.0× - best debugging/architecture

# Task-type specific overrides (research-backed)
declare -A DEBUG_MODELS
DEBUG_MODELS["simple"]="gpt-5.1-codex"
DEBUG_MODELS["complex"]="claude-opus-4-5-20251101"   # Best at contextual debugging (Anthropic)

declare -A REFACTOR_MODELS
REFACTOR_MODELS["simple"]="gpt-5.1-codex"
REFACTOR_MODELS["complex"]="claude-sonnet-4-5-20250929"  # Cleaner code (SonarSource)

declare -A REASONING_LEVELS
REASONING_LEVELS["trivial"]="low"     # none not always available
REASONING_LEVELS["simple"]="low"      # +5-10% accuracy
REASONING_LEVELS["moderate"]="medium" # +15-20% accuracy
REASONING_LEVELS["complex"]="high"    # +20-30% accuracy (eval.16x.engineer)
REASONING_LEVELS["critical"]="high"   # extra-high only on Codex-Max

# Check dependencies
command -v droid &> /dev/null || { echo "Error: droid CLI not installed"; exit 1; }
command -v jq &> /dev/null || { echo "Error: jq not installed"; exit 1; }
[ -f "$PRD_FILE" ] || { echo "Error: prd.json not found"; exit 1; }
[ -f "$PROMPT_FILE" ] || { echo "Error: prompt.md not found"; exit 1; }

# Function to assess story complexity
assess_complexity() {
    local story_json="$1"
    local score=0
    
    # Get acceptance criteria count
    local criteria_count=$(echo "$story_json" | jq '.acceptanceCriteria | length')
    
    # Score based on criteria count
    if [ "$criteria_count" -le 2 ]; then
        score=$((score + 0))
    elif [ "$criteria_count" -le 4 ]; then
        score=$((score + 1))
    elif [ "$criteria_count" -le 6 ]; then
        score=$((score + 2))
    else
        score=$((score + 3))
    fi
    
    # Get story text for keyword analysis
    local title=$(echo "$story_json" | jq -r '.title // ""' | tr '[:upper:]' '[:lower:]')
    local desc=$(echo "$story_json" | jq -r '.description // ""' | tr '[:upper:]' '[:lower:]')
    local text="$title $desc"
    
    # Check for trivial keywords (reduce score)
    if echo "$text" | grep -qE 'rename|config|typo|import|comment|format'; then
        score=$((score - 1))
    fi
    
    # Check for simple keywords
    if echo "$text" | grep -qE 'add method|basic|straightforward|minor|simple'; then
        score=$((score + 0))
    fi
    
    # Check for moderate keywords
    if echo "$text" | grep -qE 'feature|refactor|component|endpoint|test'; then
        score=$((score + 1))
    fi
    
    # Check for complex keywords (increase score)
    if echo "$text" | grep -qE 'debug|architecture|performance|security|migration'; then
        score=$((score + 2))
    fi
    
    # Check for critical keywords (increase score more)
    if echo "$text" | grep -qE 'critical|complex|design|ambiguous|novel'; then
        score=$((score + 3))
    fi
    
    # Check for VERIFY: prefixes (indicates need for more careful work)
    local verify_count=$(echo "$story_json" | jq '[.acceptanceCriteria[] | select(startswith("VERIFY"))] | length')
    if [ "$verify_count" -gt 3 ]; then
        score=$((score + 1))
    fi
    
    # Map score to complexity level
    if [ "$score" -le 0 ]; then
        echo "trivial"
    elif [ "$score" -le 1 ]; then
        echo "simple"
    elif [ "$score" -le 2 ]; then
        echo "moderate"
    elif [ "$score" -le 3 ]; then
        echo "complex"
    else
        echo "critical"
    fi
}

# Function to detect task type from story
detect_task_type() {
    local story_json="$1"
    local text=$(echo "$story_json" | jq -r '(.title // "") + " " + (.description // "")' | tr '[:upper:]' '[:lower:]')
    
    if echo "$text" | grep -qE 'debug|fix bug|error|broken|fails|crash'; then
        echo "debugging"
    elif echo "$text" | grep -qE 'refactor|restructure|reorganize|clean up'; then
        echo "refactoring"
    elif echo "$text" | grep -qE 'test|spec|coverage'; then
        echo "testing"
    elif echo "$text" | grep -qE 'architect|design|system|security'; then
        echo "architecture"
    else
        echo "newCode"
    fi
}

# Function to select model for complexity (research-backed)
select_model() {
    local complexity="$1"
    local story_json="$2"
    
    # Check if story has explicit model override
    local override_model=$(echo "$story_json" | jq -r '.model // empty')
    if [ -n "$override_model" ]; then
        echo "$override_model"
        return
    fi
    
    # Detect task type for smarter selection
    local task_type=$(detect_task_type "$story_json")
    
    # Task-type specific model selection based on research
    case "$task_type" in
        "debugging")
            if [ "$complexity" = "complex" ] || [ "$complexity" = "critical" ]; then
                # Claude Opus best for complex debugging (Anthropic, Surge AI)
                echo "claude-opus-4-5-20251101"
            else
                echo "${MODEL_TIERS[$complexity]}"
            fi
            ;;
        "refactoring")
            if [ "$complexity" = "moderate" ] || [ "$complexity" = "complex" ]; then
                # Sonnet produces cleaner code (SonarSource)
                echo "claude-sonnet-4-5-20250929"
            else
                echo "${MODEL_TIERS[$complexity]}"
            fi
            ;;
        "architecture")
            # Always use premium models for architecture
            echo "claude-opus-4-5-20251101"
            ;;
        *)
            # Default: use complexity-based selection
            echo "${MODEL_TIERS[$complexity]}"
            ;;
    esac
}

# Function to select reasoning level
select_reasoning() {
    local complexity="$1"
    local story_json="$2"
    
    # Check for override
    local override=$(echo "$story_json" | jq -r '.reasoning // empty')
    if [ -n "$override" ]; then
        echo "$override"
        return
    fi
    
    echo "${REASONING_LEVELS[$complexity]}"
}

# Initialize metrics
START_TIME=$(date +%s)
TOTAL_ITERATIONS=0
STORIES_COMPLETED=0
TOTAL_TOKENS_SAVED=0

# Initialize progress file
if [ ! -f "$PROGRESS_FILE" ]; then
    cat > "$PROGRESS_FILE" << EOF
# Droid Ralph Progress Log - STRICT MODE with SMART MODEL SELECTION
Started: $(date)
---
EOF
fi

# Initialize metrics file
cat > "$METRICS_FILE" << EOF
{
  "mode": "strict-smart",
  "startTime": "$(date -Iseconds)",
  "modelSelections": [],
  "iterations": []
}
EOF

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║   DROID RALPH - STRICT MODE + INTELLIGENT MODEL SELECT    ║"
echo "╠═══════════════════════════════════════════════════════════╣"
echo "║  Max iterations: $MAX_ITERATIONS                                       ║"
echo "║  Model selection: DYNAMIC (based on task complexity)      ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

for i in $(seq 1 $MAX_ITERATIONS); do
    ITER_START=$(date +%s)
    
    echo ""
    echo "═══════════════════════════════════════════════════════════"
    echo "  [$MODE] Iteration $i of $MAX_ITERATIONS"
    echo "═══════════════════════════════════════════════════════════"
    
    # Get remaining stories
    REMAINING=$(jq '[.userStories[] | select(.passes == false)] | length' "$PRD_FILE" 2>/dev/null || echo "0")
    
    if [ "$REMAINING" -eq 0 ]; then
        break
    fi
    
    # Get current story
    CURRENT_STORY=$(jq '[.userStories[] | select(.passes == false)] | sort_by(.priority) | .[0]' "$PRD_FILE")
    STORY_ID=$(echo "$CURRENT_STORY" | jq -r '.id // "unknown"')
    STORY_TITLE=$(echo "$CURRENT_STORY" | jq -r '.title // "unknown"')
    
    # Assess complexity
    COMPLEXITY=$(assess_complexity "$CURRENT_STORY")
    
    # Select model and reasoning
    SELECTED_MODEL=$(select_model "$COMPLEXITY" "$CURRENT_STORY")
    SELECTED_REASONING=$(select_reasoning "$COMPLEXITY" "$CURRENT_STORY")
    
    echo ""
    echo "┌─────────────────────────────────────────────────────────┐"
    echo "│ Story: $STORY_ID - $STORY_TITLE"
    echo "│ Complexity: $COMPLEXITY"
    echo "│ Model: $SELECTED_MODEL"
    echo "│ Reasoning: $SELECTED_REASONING"
    echo "│ Remaining: $REMAINING stories"
    echo "└─────────────────────────────────────────────────────────┘"
    echo ""
    
    # Run droid exec with selected model
    ITER_OUTPUT=$(droid exec \
        --auto high \
        --cwd "$SCRIPT_DIR" \
        -f "$PROMPT_FILE" \
        --model "$SELECTED_MODEL" \
        --reasoning-effort "$SELECTED_REASONING" \
        --output-format json \
        2>&1) || true
    
    ITER_END=$(date +%s)
    ITER_DURATION=$((ITER_END - ITER_START))
    TOTAL_ITERATIONS=$((TOTAL_ITERATIONS + 1))
    
    # Extract metrics
    DURATION_MS=$(echo "$ITER_OUTPUT" | jq -r '.duration_ms // 0' 2>/dev/null || echo "0")
    NUM_TURNS=$(echo "$ITER_OUTPUT" | jq -r '.num_turns // 0' 2>/dev/null || echo "0")
    
    # Check completion
    NEW_REMAINING=$(jq '[.userStories[] | select(.passes == false)] | length' "$PRD_FILE" 2>/dev/null || echo "0")
    if [ "$NEW_REMAINING" -lt "$REMAINING" ]; then
        STORIES_COMPLETED=$((STORIES_COMPLETED + 1))
        STATUS="completed"
    else
        STATUS="incomplete"
    fi
    
    # Update metrics
    jq --arg iter "$i" \
       --arg story "$STORY_ID" \
       --arg status "$STATUS" \
       --arg duration "$ITER_DURATION" \
       --arg model "$SELECTED_MODEL" \
       --arg complexity "$COMPLEXITY" \
       --arg reasoning "$SELECTED_REASONING" \
       --arg turns "$NUM_TURNS" \
       '.iterations += [{
         "iteration": ($iter | tonumber),
         "story": $story,
         "status": $status,
         "complexity": $complexity,
         "model": $model,
         "reasoning": $reasoning,
         "duration_seconds": ($duration | tonumber),
         "turns": ($turns | tonumber)
       }]' "$METRICS_FILE" > "$METRICS_FILE.tmp" && mv "$METRICS_FILE.tmp" "$METRICS_FILE"
    
    echo ""
    echo "Iteration $i: $STATUS | Model: $SELECTED_MODEL | ${ITER_DURATION}s"
    
    # Check for completion signal
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

# Calculate model usage summary
MODEL_SUMMARY=$(jq -r '[.iterations[].model] | group_by(.) | map({model: .[0], count: length}) | .[]' "$METRICS_FILE" 2>/dev/null || echo "{}")

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
     "storiesRemaining": ($remaining | tonumber)
   }' "$METRICS_FILE" > "$METRICS_FILE.tmp" && mv "$METRICS_FILE.tmp" "$METRICS_FILE"

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║         STRICT-SMART MODE - FINAL RESULTS                 ║"
echo "╠═══════════════════════════════════════════════════════════╣"
printf "║  Stories completed: %-3s / %-3s                            ║\n" "$STORIES_COMPLETED" "$TOTAL_STORIES"
printf "║  Total iterations:  %-3s                                   ║\n" "$TOTAL_ITERATIONS"
printf "║  Total time:        %-4ss                                 ║\n" "$TOTAL_DURATION"
echo "║                                                           ║"
echo "║  Model Usage:                                             ║"
jq -r '.iterations | group_by(.model) | .[] | "║    \(.[0].model): \(length) tasks"' "$METRICS_FILE" 2>/dev/null || true
echo "║                                                           ║"
echo "║  Metrics: metrics.json                                    ║"
echo "╚═══════════════════════════════════════════════════════════╝"

[ "$FINAL_REMAINING" -eq 0 ] && exit 0 || exit 1
