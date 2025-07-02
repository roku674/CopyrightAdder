# Copyright © Alexander Fields, 2025. All Rights Reserved. Created by Alexander Fields https://www.alexanderfields.me on 2025-07-02 09:35:27
# Edited by Alexander Fields https://www.alexanderfields.me 2025-07-02 11:48:15
#!/bin/bash

# Automatically adds copyright headers with correct attribution based on git history
# Works with any git repository

# Function to read configuration from sources.txt
read_config() {
    local config_file="sources.txt"
    
    # Check if sources.txt exists in current directory
    if [ ! -f "$config_file" ]; then
        # Check if it exists in script directory
        local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        config_file="$script_dir/sources.txt"
        
        if [ ! -f "$config_file" ]; then
            echo "Error: sources.txt not found!"
            echo "Please create a sources.txt file with configuration."
            exit 1
        fi
    fi
    
    # Read configuration values
    COMPANY_NAME=""
    RIGHTS_STATEMENT=""
    SPECIAL_AUTHORS=()
    EXCLUDE_DIRS=()
    FILE_EXTENSIONS=()
    
    while IFS='=' read -r key value; do
        # Skip comments and empty lines
        [[ "$key" =~ ^#.*$ ]] && continue
        [[ -z "$key" ]] && continue
        
        # Trim whitespace
        key=$(echo "$key" | xargs)
        value=$(echo "$value" | xargs)
        
        case "$key" in
            COMPANY_NAME)
                COMPANY_NAME="$value"
                ;;
            RIGHTS_STATEMENT)
                RIGHTS_STATEMENT="$value"
                ;;
            SPECIAL_AUTHOR_*)
                if [ -n "$value" ]; then
                    SPECIAL_AUTHORS+=("$value")
                fi
                ;;
            EXCLUDE_DIR_*)
                if [ -n "$value" ]; then
                    EXCLUDE_DIRS+=("$value")
                fi
                ;;
            FILE_EXT_*)
                if [ -n "$value" ]; then
                    FILE_EXTENSIONS+=("$value")
                fi
                ;;
        esac
    done < "$config_file"
    
    # Set defaults if not configured
    if [ -z "$COMPANY_NAME" ]; then
        COMPANY_NAME="Alexander"
    fi
}

# Load configuration
read_config

# Function to get author info from git
get_git_author_info() {
    local file="$1"
    local info=""
    
    # Get the first commit that created this file with full timestamp
    info=$(git log --diff-filter=A --follow --format='%an|%ae|%ad' --date=format:'%Y|%Y-%m-%d %H:%M:%S' -- "$file" 2>/dev/null | tail -1)
    
    if [ -z "$info" ]; then
        # If file not in git history yet, try to get current git user
        local current_author=$(git config user.name 2>/dev/null || echo "Unknown")
        local current_email=$(git config user.email 2>/dev/null || echo "unknown@unknown.com")
        local current_year=$(date +%Y)
        local current_timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        info="$current_author|$current_email|$current_year|$current_timestamp"
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
        # JSON style - special handling
        json)
            comment_style="json_special"
            ;;
        # Skip unknown types
        *)
            echo "Skipping unknown file type: $file"
            return
            ;;
    esac
    
    # Get author info from git
    local author_info=$(get_git_author_info "$file")
    IFS='|' read -r author_name author_email year_and_timestamp <<< "$author_info"
    
    # Parse year and timestamp from the combined field
    IFS='|' read -r year creation_timestamp <<< "$year_and_timestamp"
    
    # Format the author
    formatted_author=$(format_author "$author_name" "$author_email")
    
    # Get last editor info from git
    editor_info=$(git log -1 --format='%an|%ae|%ad' --date=format:'%Y-%m-%d %H:%M:%S' -- "$file" 2>/dev/null)
    if [ -n "$editor_info" ]; then
        IFS='|' read -r editor_name editor_email editor_date <<< "$editor_info"
        formatted_editor=$(format_author "$editor_name" "$editor_email")
    fi
    
    # Build the copyright header with creation timestamp from git
    if [ -n "$RIGHTS_STATEMENT" ]; then
        local copyright_text="Copyright © $COMPANY_NAME, $year. $RIGHTS_STATEMENT Created by $formatted_author on $creation_timestamp"
    else
        local copyright_text="Copyright © $COMPANY_NAME, $year. All Rights Reserved. Created by $formatted_author on $creation_timestamp"
    fi
    
    # Add edited by info if editor is different from author
    local edited_text=""
    if [ -n "$editor_email" ] && [ "$editor_email" != "$author_email" ]; then
        edited_text="Edited by $formatted_editor $editor_date"
    fi
    
    # Handle JSON files specially
    if [ "$comment_style" = "json_special" ]; then
        # For JSON files, we need to add/update the "copyright" key
        if [ -f "$file" ] && [ -s "$file" ]; then
            # Check if file already has copyright key
            if grep -q '"copyright"' "$file"; then
                echo "File already has copyright key, updating: $file"
                # Update existing copyright value
                temp_file=$(mktemp)
                if [ -n "$edited_text" ]; then
                    jq --arg copyright "$copyright_text" --arg edited "$edited_text" \
                        '.copyright = ($copyright + ", " + $edited)' "$file" > "$temp_file" 2>/dev/null || {
                        # If jq fails, try simple sed replacement
                        sed -E "s/\"copyright\"[[:space:]]*:[[:space:]]*\"[^\"]*\"/\"copyright\": \"$copyright_text, $edited_text\"/" "$file" > "$temp_file"
                    }
                else
                    jq --arg copyright "$copyright_text" \
                        '.copyright = $copyright' "$file" > "$temp_file" 2>/dev/null || {
                        # If jq fails, try simple sed replacement
                        sed -E "s/\"copyright\"[[:space:]]*:[[:space:]]*\"[^\"]*\"/\"copyright\": \"$copyright_text\"/" "$file" > "$temp_file"
                    }
                fi
                mv "$temp_file" "$file"
            else
                echo "Adding copyright key to JSON: $file"
                # Add copyright key to JSON
                temp_file=$(mktemp)
                if [ -n "$edited_text" ]; then
                    copyright_value="$copyright_text, $edited_text"
                else
                    copyright_value="$copyright_text"
                fi
                
                # Try to add copyright as first key using jq
                jq --arg copyright "$copyright_value" '. = {copyright: $copyright} + .' "$file" > "$temp_file" 2>/dev/null || {
                    # If jq is not available or fails, do simple string manipulation
                    # Read first line
                    first_line=$(head -n 1 "$file")
                    if [[ "$first_line" == "{"* ]]; then
                        # Add copyright after opening brace
                        echo "{" > "$temp_file"
                        echo "  \"copyright\": \"$copyright_value\"," >> "$temp_file"
                        tail -n +2 "$file" | sed '1s/^/  /' >> "$temp_file"
                    else
                        # Couldn't parse, skip
                        echo "Warning: Could not parse JSON structure in $file"
                        return
                    fi
                }
                mv "$temp_file" "$file"
            fi
        else
            # Empty or new JSON file
            echo "{" > "$file"
            echo "  \"copyright\": \"$copyright_text\"" >> "$file"
            echo "}" >> "$file"
        fi
    else
        # Non-JSON files - use comment-based headers
        local header="${comment_style} $copyright_text${comment_end}"
        local header2=""
        if [ -n "$edited_text" ]; then
            header2="${comment_style} $edited_text${comment_end}"
        fi
        
        # Check if file already has a copyright header in the first 10 lines
        if head -n 10 "$file" | grep -q "Copyright.*©.*$COMPANY_NAME\|Copyright.*$COMPANY_NAME"; then
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
    fi
    
    echo "Processed: $file (Author: $formatted_author, Year: $year)"
}

# Function to find all source files
find_source_files() {
    # Build find command with exclusions from config
    local find_cmd="find . -type f"
    for dir in "${EXCLUDE_DIRS[@]}"; do
        find_cmd="$find_cmd -not -path '*/$dir/*' -not -name '$dir'"
    done
    
    # Add file extensions to search for from config
    if [ ${#FILE_EXTENSIONS[@]} -gt 0 ]; then
        find_cmd="$find_cmd \("
        local first=true
        for ext in "${FILE_EXTENSIONS[@]}"; do
            if [ "$first" = true ]; then
                find_cmd="$find_cmd -name '*.$ext'"
                first=false
            else
                find_cmd="$find_cmd -o -name '*.$ext'"
            fi
        done
        find_cmd="$find_cmd \)"
    fi
    
    # Exclude minified files and migrations
    find_cmd="$find_cmd -not -name '*.min.js' -not -name '*.min.css' -not -path '*/migrations/*'"
    
    eval "$find_cmd"
}

# Function to process a single git repository
process_single_repo() {
    local repo_path="$1"
    echo "Processing repository: $repo_path"
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
    echo "Copyright headers added successfully for $repo_path!"
    echo ""
}

# Function to find all git repositories recursively
find_git_repos() {
    local search_path="${1:-.}"
    find "$search_path" -type d -name ".git" 2>/dev/null | while read -r git_dir; do
        echo "$(dirname "$git_dir")"
    done
}

# Main execution
main() {
    # Check if we're in a git repository
    if git rev-parse --git-dir > /dev/null 2>&1; then
        # Single repository mode
        echo "Adding copyright headers based on git history..."
        process_single_repo "$(pwd)"
    else
        # Multi-repository mode
        echo "Not in a git repository. Searching for git repositories recursively..."
        echo ""
        
        local repos_found=0
        local repos_processed=0
        
        # Find all git repositories
        while IFS= read -r repo; do
            ((repos_found++))
        done < <(find_git_repos ".")
        
        if [ $repos_found -eq 0 ]; then
            echo "No git repositories found in the current directory tree."
            exit 1
        fi
        
        echo "Found $repos_found git repositories. Processing..."
        echo "=" 
        echo ""
        
        # Process each repository
        find_git_repos "." | while IFS= read -r repo; do
            ((repos_processed++))
            echo "[$repos_processed/$repos_found] Entering repository: $repo"
            echo "-"
            
            # Change to repository directory
            (
                cd "$repo" || continue
                process_single_repo "$repo"
            )
            
            echo "="
            echo ""
        done
        
        echo "All repositories processed!"
    fi
    
    echo "To customize this script:"
    echo "  - Edit sources.txt file in the script directory"
    echo "  - Update COMPANY_NAME and RIGHTS_STATEMENT values"
    echo "  - Add SPECIAL_AUTHOR entries for special author formatting"
    echo "  - Add FILE_EXT entries for additional file types"
    echo "  - Add EXCLUDE_DIR entries to skip directories"
}

# Run main function
main "$@"
