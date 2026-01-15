#!/bin/bash
# Initialize a project for Droid Ralph
# Usage: ./init-project.sh [project_dir] [mode: normal|strict]

PROJECT_DIR="${1:-.}"
MODE="${2:-strict}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DROID_DIR="$(dirname "$SCRIPT_DIR")"

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║         DROID RALPH - PROJECT INITIALIZATION              ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""
echo "Project: $PROJECT_DIR"
echo "Mode: $MODE"
echo ""

# Create project directory if needed
mkdir -p "$PROJECT_DIR"

# Copy appropriate files based on mode
if [ "$MODE" = "strict" ]; then
    SOURCE_DIR="$DROID_DIR/strict"
elif [ "$MODE" = "normal" ]; then
    SOURCE_DIR="$DROID_DIR/normal"
else
    echo "Error: Invalid mode. Use 'normal' or 'strict'"
    exit 1
fi

echo "Copying Ralph files..."
cp "$SOURCE_DIR/ralph.sh" "$PROJECT_DIR/"
cp "$SOURCE_DIR/prompt.md" "$PROJECT_DIR/"

echo "Creating AGENTS.md from template..."
if [ -f "$DROID_DIR/templates/AGENTS.md.template" ]; then
    cp "$DROID_DIR/templates/AGENTS.md.template" "$PROJECT_DIR/AGENTS.md"
else
    cat > "$PROJECT_DIR/AGENTS.md" << 'EOF'
<coding_guidelines>
# Project Intelligence

## Quick Reference

### Critical Commands
```bash
# Build
npm run build

# Test
npm test

# Lint
npm run lint
```

## Code Patterns
<!-- Add patterns as you discover them -->

## Known Gotchas
<!-- Add gotchas as you encounter them -->

## Recent Learnings
<!-- Auto-populated from iterations -->

</coding_guidelines>
EOF
fi

echo "Creating progress.txt..."
cat > "$PROJECT_DIR/progress.txt" << EOF
# Droid Ralph Progress Log
Mode: $MODE
Started: $(date)

## Codebase Patterns
<!-- Add reusable patterns here -->

---
EOF

echo "Creating prd.json template..."
cat > "$PROJECT_DIR/prd.json" << 'EOF'
{
  "project": "YOUR_PROJECT_NAME",
  "branchName": "feature/your-feature",
  "description": "Feature description",
  "qualityChecks": {
    "typecheck": "npm run typecheck || echo 'no typecheck'",
    "lint": "npm run lint || echo 'no lint'",
    "test": "npm test || echo 'no test'"
  },
  "userStories": [
    {
      "id": "US-001",
      "title": "First story",
      "description": "As a user, I want...",
      "acceptanceCriteria": [
        "Criterion 1",
        "Criterion 2",
        "Build passes"
      ],
      "priority": 1,
      "passes": false,
      "notes": ""
    }
  ]
}
EOF

# Make script executable
chmod +x "$PROJECT_DIR/ralph.sh" 2>/dev/null || true

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║              INITIALIZATION COMPLETE                      ║"
echo "╠═══════════════════════════════════════════════════════════╣"
echo "║  Files created:                                           ║"
echo "║    - ralph.sh (main script)                               ║"
echo "║    - prompt.md (AI instructions)                          ║"
echo "║    - AGENTS.md (pattern memory)                           ║"
echo "║    - progress.txt (iteration log)                         ║"
echo "║    - prd.json (edit with your stories)                    ║"
echo "╠═══════════════════════════════════════════════════════════╣"
echo "║  Next steps:                                              ║"
echo "║    1. Edit prd.json with your user stories                ║"
echo "║    2. Fill in AGENTS.md with known patterns               ║"
echo "║    3. Run: ./ralph.sh                                     ║"
echo "╚═══════════════════════════════════════════════════════════╝"
