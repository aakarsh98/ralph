#!/bin/bash
# Consolidate patterns from progress.txt into AGENTS.md
# Usage: ./consolidate-patterns.sh [project_dir]

PROJECT_DIR="${1:-.}"
PROGRESS_FILE="$PROJECT_DIR/progress.txt"
AGENTS_FILE="$PROJECT_DIR/AGENTS.md"
TEMPLATE_FILE="$(dirname "$0")/../templates/AGENTS.md.template"

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║         PATTERN CONSOLIDATION UTILITY                     ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# Check if progress.txt exists
if [ ! -f "$PROGRESS_FILE" ]; then
    echo "Error: progress.txt not found at $PROGRESS_FILE"
    exit 1
fi

# Create AGENTS.md from template if it doesn't exist
if [ ! -f "$AGENTS_FILE" ]; then
    if [ -f "$TEMPLATE_FILE" ]; then
        echo "Creating AGENTS.md from template..."
        cp "$TEMPLATE_FILE" "$AGENTS_FILE"
    else
        echo "Creating basic AGENTS.md..."
        cat > "$AGENTS_FILE" << 'EOF'
<coding_guidelines>
# Project Intelligence

## Codebase Patterns
<!-- Patterns discovered during development -->

## Known Gotchas
<!-- Things to avoid -->

## Recent Learnings
<!-- Auto-consolidated from progress.txt -->

</coding_guidelines>
EOF
    fi
fi

echo "Scanning progress.txt for patterns..."
echo ""

# Extract patterns from progress.txt
echo "## Patterns Found in progress.txt:"
echo ""

# Look for pattern indicators
grep -E "Pattern:|pattern:|PATTERN:" "$PROGRESS_FILE" 2>/dev/null | while read -r line; do
    echo "  - $line"
done

echo ""
echo "## Gotchas Found:"
echo ""

grep -E "Gotcha:|gotcha:|GOTCHA:|avoid:|Avoid:" "$PROGRESS_FILE" 2>/dev/null | while read -r line; do
    echo "  - $line"
done

echo ""
echo "## Learnings Found:"
echo ""

grep -E "Learning:|learning:|Discovered:|discovered:" "$PROGRESS_FILE" 2>/dev/null | while read -r line; do
    echo "  - $line"
done

# Extract Codebase Patterns section if it exists
echo ""
echo "## Codebase Patterns Section:"
echo ""

if grep -q "## Codebase Patterns" "$PROGRESS_FILE"; then
    # Extract content between "## Codebase Patterns" and next "##" or "---"
    sed -n '/## Codebase Patterns/,/^##\|^---/p' "$PROGRESS_FILE" | head -20
else
    echo "  (No Codebase Patterns section found)"
fi

echo ""
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "To consolidate, manually review the above and add to:"
echo "  $AGENTS_FILE"
echo ""
echo "Sections to update:"
echo "  - ## Code Patterns"
echo "  - ## Known Gotchas"
echo "  - ## Recent Learnings"
echo ""
