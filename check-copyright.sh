# Copyright © Alexander Fields, 2025. All Rights Reserved. Created by Alexander Fields https://www.alexanderfields.me on 2025-07-02 16:19:48
#!/bin/bash
# Run copyright header check locally

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Change to the parent directory (project root)
cd "$SCRIPT_DIR/.." || exit 1

echo "Running copyright header check..."

# Capture the output and exit code
output=$("$SCRIPT_DIR/add_copyright_headers.sh" 2>&1)
exit_code=$?

# Display the output
echo "$output"

# Check exit code first
if [ $exit_code -ne 0 ]; then
    echo ""
    echo "❌ Copyright header check failed with exit code: $exit_code"
    exit $exit_code
fi

# Check for actual changes (excluding CopyrightAdder directory and check-copyright.sh)
changes=$(git status --porcelain | grep -v "^?? CopyrightAdder/" | grep -v "^?? check-copyright.sh")
if [[ -n "$changes" ]]; then
    echo ""
    echo "⚠️  Copyright headers were added to some files."
    echo "Please review the changes and commit them."
else
    echo ""
    echo "✅ All files have proper copyright headers."
fi

# Always exit with success if we got here
exit 0
