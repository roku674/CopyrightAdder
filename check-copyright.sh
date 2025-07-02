#!/bin/bash
# Run copyright header check locally
# Usage: ./CopyrightAdder/check-copyright.sh

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Change to the parent directory (project root)
cd "$SCRIPT_DIR/.." || exit 1

echo "Running copyright header check..."
"$SCRIPT_DIR/add_copyright_headers.sh"

if [[ -n $(git status --porcelain) ]]; then
    echo ""
    echo "⚠️  Copyright headers were added to some files."
    echo "Please review the changes and commit them."
else
    echo ""
    echo "✅ All files have proper copyright headers."
fi