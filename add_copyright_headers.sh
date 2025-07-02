#!/bin/bash

# Universal Copyright Header Script
# Automatically adds copyright headers with correct attribution based on git history
# Works with any git repository

# Configuration
COMPANY_NAME="${COMPANY_NAME:-Alexander}"  # Can be overridden by environment variable
RIGHTS_STATEMENT="${RIGHTS_STATEMENT:-}"  # Can be overridden by environment variable (e.g., "All Rights Reserved")
SPECIAL_AUTHORS=(
    "roku674@gmail.com|Alexander Fields|https://www.alexanderfields.me"
    # Add more special authors here in format: email|name|website
)

# Function to get author info from git
get_git_author_info() {
    local file="$1"
    local info=""
    
    # Get the first commit that created this file
    info=$(git log --diff-filter=A --follow --format='%an|%ae|%ad' --date=format:'%Y' -- "$file" 2>/dev/null | tail -1)
    
    if [ -z "$info" ]; then
        # If file not in git history yet, try to get current git user
        local current_author=$(git config user.name 2>/dev/null || echo "Unknown")
        local current_email=$(git config user.email 2>/dev/null || echo "unknown@unknown.com")
        local current_year=$(date +%Y)
        info="$current_author|$current_email|$current_year"
    fi
    
    echo "$info"
}

# Function to format author with special handling
format_author() {
    local author_name="$1"
    local author_email="$2"
    
    # Check if this is a special author
    for special in "${SPECIAL_AUTHORS[@]}"; do
        IFS='|' read -r email name website <<< "$special"
        if [[ "$author_email" == "$email" ]] || [[ "$author_name" == "$name" ]]; then
            if [ -n "$website" ]; then
                echo "$name $website"
            else
                echo "$name"
            fi
            return
        fi
    done
    
    # Default format for other authors
    echo "$author_name"
}

# Function to add copyright header to a file
add_copyright_header() {
    local file="$1"
    
    # Skip if file doesn't exist
    if [ ! -f "$file" ]; then
        return
    fi
    
    # Get file extension
    local ext="${file##*.}"
    local comment_style=""
    
    # Determine comment style based on file extension
    case "$ext" in
        # C-style comments
        c|cc|cpp|cs|java|js|jsx|ts|tsx|go|swift|kt|scala|groovy|dart|rs)
            comment_style="//"
            ;;
        # Hash comments
        py|rb|sh|bash|zsh|pl|r|jl|nim|cr|ex|exs|yaml|yml|toml)
            comment_style="#"
            ;;
        # XML/HTML style
        xml|html|htm|svg)
            comment_style="<!--"
            comment_end=" -->"
            ;;
        # SQL style
        sql)
            comment_style="--"
            ;;
        # Lisp style
        lisp|clj|scm|el)
            comment_style=";;"
            ;;
        # Skip unknown types
        *)
            echo "Skipping unknown file type: $file"
            return
            ;;
    esac
    
    # Get author info from git
    IFS='|' read -r author_name author_email year <<< "$(get_git_author_info "$file")"
    
    # Format the author
    formatted_author=$(format_author "$author_name" "$author_email")
    
    # Get last editor info from git
    editor_info=$(git log -1 --format='%an|%ae|%ad' --date=format:'%Y-%m-%d %H:%M:%S' -- "$file" 2>/dev/null)
    if [ -n "$editor_info" ]; then
        IFS='|' read -r editor_name editor_email editor_date <<< "$editor_info"
        formatted_editor=$(format_author "$editor_name" "$editor_email")
    fi
    
    # Build the copyright header
    if [ -n "$RIGHTS_STATEMENT" ]; then
        local header="${comment_style} Copyright $COMPANY_NAME, $year. $RIGHTS_STATEMENT Created by $formatted_author${comment_end}"
    else
        local header="${comment_style} Copyright $COMPANY_NAME, $year. All Rights Reserved. Created by $formatted_author${comment_end}"
    fi
    
    # Add edited by line if editor is different from author
    local header2=""
    if [ -n "$editor_email" ] && [ "$editor_email" != "$author_email" ]; then
        header2="${comment_style} Edited by $formatted_editor $editor_date${comment_end}"
    fi
    
    # Check if file already has a copyright header in the first 10 lines
    if head -n 10 "$file" | grep -q "Copyright.*$COMPANY_NAME"; then
        echo "File already has copyright header, updating: $file"
        # Create temp file without old copyright and edited by lines
        temp_file=$(mktemp)
        awk '
            BEGIN {line_count=0} 
            {line_count++}
            line_count <= 15 && ($0 ~ /Copyright/ || $0 ~ /Edited by/) {next}
            {print}
        ' "$file" > "$temp_file"
        
        # Add new headers and rest of file
        echo "$header" > "$file"
        if [ -n "$header2" ]; then
            echo "$header2" >> "$file"
        fi
        cat "$temp_file" >> "$file"
        rm "$temp_file"
    else
        # Add new copyright headers at the beginning
        temp_file=$(mktemp)
        echo "$header" > "$temp_file"
        if [ -n "$header2" ]; then
            echo "$header2" >> "$temp_file"
        fi
        cat "$file" >> "$temp_file"
        mv "$temp_file" "$file"
    fi
    
    echo "Processed: $file (Author: $formatted_author, Year: $year)"
}

# Function to find all source files
find_source_files() {
    local exclude_dirs=(
        "node_modules"
        ".git"
        "dist"
        "build"
        "bin"
        "obj"
        "target"
        ".next"
        ".nuxt"
        "coverage"
        "__pycache__"
        ".pytest_cache"
        "vendor"
        "packages"
        ".vs"
        ".vscode"
        ".idea"
    )
    
    # Build find command with exclusions
    local find_cmd="find . -type f"
    for dir in "${exclude_dirs[@]}"; do
        find_cmd="$find_cmd -not -path './$dir/*'"
    done
    
    # Add file extensions to search for
    find_cmd="$find_cmd \( -name '*.c' -o -name '*.cc' -o -name '*.cpp' -o -name '*.cs' \
        -o -name '*.java' -o -name '*.js' -o -name '*.jsx' -o -name '*.ts' -o -name '*.tsx' \
        -o -name '*.go' -o -name '*.swift' -o -name '*.kt' -o -name '*.scala' -o -name '*.groovy' \
        -o -name '*.dart' -o -name '*.rs' -o -name '*.py' -o -name '*.rb' -o -name '*.sh' \
        -o -name '*.pl' -o -name '*.r' -o -name '*.jl' -o -name '*.nim' -o -name '*.cr' \
        -o -name '*.ex' -o -name '*.exs' -o -name '*.sql' -o -name '*.lisp' -o -name '*.clj' \
        -o -name '*.scm' -o -name '*.el' \)"
    
    # Exclude minified files and migrations
    find_cmd="$find_cmd -not -name '*.min.js' -not -name '*.min.css' -not -path '*/migrations/*'"
    
    eval "$find_cmd"
}

# Main execution
main() {
    # Check if we're in a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo "Error: Not in a git repository!"
        exit 1
    fi
    
    echo "Adding copyright headers based on git history..."
    echo "Company: $COMPANY_NAME"
    if [ -n "$RIGHTS_STATEMENT" ]; then
        echo "Rights: $RIGHTS_STATEMENT"
    fi
    echo ""
    
    # Process all source files
    find_source_files | while IFS= read -r file; do
        add_copyright_header "$file"
    done
    
    echo ""
    echo "Copyright headers added successfully!"
    echo ""
    echo "To customize this script:"
    echo "  - Set COMPANY_NAME environment variable"
    echo "  - Set RIGHTS_STATEMENT environment variable (e.g., 'All Rights Reserved')"
    echo "  - Edit SPECIAL_AUTHORS array in the script"
    echo "  - Add more file extensions in find_source_files function"
}

# Run main function
main "$@"