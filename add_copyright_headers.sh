# Copyright © Alexander Fields, 2025. All Rights Reserved. Created by Alexander Fields https://www.alexanderfields.me on 2025-07-02 09:35:27
# Edited by Alexander Fields https://www.alexanderfields.me 2025-07-02 17:25:28
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
    EXCLUDE_FILES=()
    
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
            EXCLUDE_FILE_*)
                if [ -n "$value" ]; then
                    EXCLUDE_FILES+=("$value")
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

# Set maximum parallel jobs (can be overridden by environment variable)
MAX_PARALLEL_JOBS=${MAX_PARALLEL_JOBS:-8}

# Track number of active jobs
declare -i active_jobs=0

# Function to wait for a job slot to become available
wait_for_job_slot() {
    while [ $(jobs -r | wc -l) -ge $MAX_PARALLEL_JOBS ]; do
        sleep 0.1
    done
}

# Function to process files in a directory in parallel
process_directory_files() {
    local dir="$1"
    local -a files=()
    local -a files_to_process=()
    
    # Find files in this specific directory (not subdirectories)
    while IFS= read -r file; do
        files+=("$file")
    done < <(find "$dir" -maxdepth 1 -type f 2>/dev/null)
    
    # Filter files that should be processed
    for file in "${files[@]}"; do
        if should_process_file "$file"; then
            files_to_process+=("$file")
        fi
    done
    
    # Process files in this directory
    local file_count=${#files_to_process[@]}
    if [ $file_count -gt 0 ]; then
        if [ "$dir" = "." ]; then
            echo "Processing $file_count files in root directory"
        else
            echo "Processing $file_count files in: $dir"
        fi
        
        for file in "${files_to_process[@]}"; do
            wait_for_job_slot
            add_copyright_header "$file" &
        done
    fi
}

# Function to check if a file should be processed
should_process_file() {
    local file="$1"
    local basename=$(basename "$file")
    local ext="${basename##*.}"
    
    # Skip minified files
    if [[ "$basename" == *.min.js ]] || [[ "$basename" == *.min.css ]]; then
        return 1
    fi
    
    # Check if file is in exclude list
    for excluded_file in "${EXCLUDE_FILES[@]}"; do
        if [[ "$basename" == "$excluded_file" ]]; then
            return 1
        fi
    done
    
    # Skip if no file extensions configured
    if [ ${#FILE_EXTENSIONS[@]} -eq 0 ]; then
        return 0
    fi
    
    # Check if extension matches
    for allowed_ext in "${FILE_EXTENSIONS[@]}"; do
        if [[ "$ext" == "$allowed_ext" ]]; then
            return 0
        fi
    done
    
    return 1
}

# Function to get author info from git
get_git_author_info() {
    local file="$1"
    local info=""
    local source_branch="${SOURCE_BRANCH:-HEAD}"

    # First, ensure we have full git history
    git fetch --unshallow 2>/dev/null || true

    # Get the first commit that created this file (use --reverse to get oldest first)
    # Use --follow to track renames, and filter out bot commits
    info=$(git log --diff-filter=A --follow --reverse --format='%an|%ae|%ad' --date=format:'%Y|%Y-%m-%d %H:%M:%S' -- "$file" 2>/dev/null | \
           grep -v "github-actions\[bot\]" | \
           grep -v "dependabot\[bot\]" | \
           grep -v "renovate\[bot\]" | \
           head -1)

    # If no creator found, check if file exists in base branch history
    if [ -z "$info" ] && [ "$source_branch" != "HEAD" ]; then
        # Try checking the full history from origin
        info=$(git log origin/"$source_branch" --diff-filter=A --follow --reverse --format='%an|%ae|%ad' --date=format:'%Y|%Y-%m-%d %H:%M:%S' -- "$file" 2>/dev/null | \
               grep -v "github-actions\[bot\]" | \
               grep -v "dependabot\[bot\]" | \
               grep -v "renovate\[bot\]" | \
               head -1)
    fi

    if [ -z "$info" ]; then
        # If file not in git history yet (new file), get PR author from environment
        # GitHub Actions sets these variables
        if [ -n "${GITHUB_ACTOR}" ] && [ "${GITHUB_ACTOR}" != "github-actions[bot]" ]; then
            local pr_author="${GITHUB_ACTOR}"
            local pr_email="${GITHUB_ACTOR_EMAIL:-${pr_author}@users.noreply.github.com}"
            local current_year=$(date +%Y)
            local current_timestamp=$(date '+%Y-%m-%d %H:%M:%S')
            info="${pr_author}|${pr_email}|${current_year}|${current_timestamp}"
        else
            # Last resort: get from recent commits (not current config which might be bot)
            info=$(git log --format='%an|%ae|%ad' --date=format:'%Y|%Y-%m-%d %H:%M:%S' 2>/dev/null | \
                   grep -v "github-actions\[bot\]" | \
                   grep -v "dependabot\[bot\]" | \
                   grep -v "renovate\[bot\]" | \
                   head -1)
        fi
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
    
    # Check if file should be processed
    if ! should_process_file "$file"; then
        echo "Skipping excluded file: $file"
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
        py|rb|sh|bash|zsh|pl|r|jl|nim|cr|ex|exs|toml)
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
    local author_info=$(get_git_author_info "$file")
    IFS='|' read -r author_name author_email year_and_timestamp <<< "$author_info"
    
    # Parse year and timestamp from the combined field
    IFS='|' read -r year creation_timestamp <<< "$year_and_timestamp"
    
    # Format the author
    formatted_author=$(format_author "$author_name" "$author_email")
    
    # Get ALL unique editors from git history (consolidate multiple edits by same person)
    declare -A editors_map  # Associative array to track unique editors
    local source_branch="${SOURCE_BRANCH:-HEAD}"

    # Get all commits for this file, extract unique editors with their latest edit date
    while IFS='|' read -r name email date_time; do
        # Skip bots and the original author
        if [[ "$email" == *"[bot]"* ]] || [ "$email" == "$author_email" ]; then
            continue
        fi
        # Store only the latest edit date for each unique editor
        if [ -z "${editors_map[$email]}" ] || [[ "$date_time" > "${editors_map[$email]##*|}" ]]; then
            editors_map["$email"]="$name|$date_time"
        fi
    done < <(git log --format='%an|%ae|%ad' --date=format:'%Y-%m-%d %H:%M:%S' -- "$file" 2>/dev/null | \
             grep -v "github-actions\[bot\]" | \
             grep -v "dependabot\[bot\]" | \
             grep -v "renovate\[bot\]")
    
    # Build the copyright header with creation timestamp from git
    if [ -n "$RIGHTS_STATEMENT" ]; then
        local copyright_text="Copyright © $COMPANY_NAME, $year. $RIGHTS_STATEMENT Created by $formatted_author on $creation_timestamp"
    else
        local copyright_text="Copyright © $COMPANY_NAME, $year. All Rights Reserved. Created by $formatted_author on $creation_timestamp"
    fi
    
    # Build edited by lines for all unique editors
    local edited_lines=()
    for editor_email in "${!editors_map[@]}"; do
        IFS='|' read -r editor_name editor_date <<< "${editors_map[$editor_email]}"
        local formatted_editor=$(format_author "$editor_name" "$editor_email")
        edited_lines+=("Edited by $formatted_editor $editor_date")
    done

    # Sort edited lines by date (newest first)
    IFS=$'\n' edited_lines=($(printf '%s\n' "${edited_lines[@]}" | sort -t' ' -k5 -r))
    
    # Non-JSON files - use comment-based headers
    if [ -n "$comment_style" ]; then
        local headers=()
        headers+=("${comment_style} $copyright_text${comment_end}")
        for edited_line in "${edited_lines[@]}"; do
            headers+=("${comment_style} $edited_line${comment_end}")
        done
        
        # Check if file already has a copyright header in the first 10 lines
        if head -n 10 "$file" | grep -q "Copyright.*©.*$COMPANY_NAME\|Copyright.*$COMPANY_NAME"; then
            echo "File already has copyright header, updating: $file"
            # Create temp file and extract existing edited by lines
            temp_file=$(mktemp)
            existing_edited_lines=$(mktemp)
            
            # Extract existing "Edited by" lines but exclude the current editor if they're the same person
            awk -v current_editor="$formatted_editor" '
                BEGIN {line_count=0} 
                {line_count++}
                line_count <= 15 && $0 ~ /Edited by/ {
                    # Check if this edited by line is for the same person as current editor
                    if (index($0, current_editor) == 0) {
                        print $0 > "'$existing_edited_lines'"
                    }
                    next
                }
                line_count <= 15 && $0 ~ /Copyright/ {next}
                {print}
            ' "$file" > "$temp_file"
            
            # Add all new headers
            first=true
            for header_line in "${headers[@]}"; do
                if [ "$first" = true ]; then
                    echo "$header_line" > "$file"
                    first=false
                else
                    echo "$header_line" >> "$file"
                fi
            done
            cat "$temp_file" >> "$file"
            rm "$temp_file" "$existing_edited_lines"
        else
            # Add new copyright headers at the beginning
            temp_file=$(mktemp)
            for header_line in "${headers[@]}"; do
                echo "$header_line" >> "$temp_file"
            done
            cat "$file" >> "$temp_file"
            mv "$temp_file" "$file"
        fi
    fi
    
    # Use a lock file for thread-safe output
    {
        echo "Processed: $file (Author: $formatted_author, Year: $year)"
    } 2>/dev/null
}

# Function to find all source files
find_source_files() {
    # Build find command with exclusions from config
    local find_cmd="find . -type f"
    
    # Always exclude dot directories like .github, .git, .vscode, etc.
    find_cmd="$find_cmd -not -path '*/.*'"
    
    # Add configured exclusions
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

# Function to process a single git repository with parallel processing
process_single_repo() {
    local repo_path="$1"
    echo "Processing repository: $repo_path"
    echo "Company: $COMPANY_NAME"
    if [ -n "$RIGHTS_STATEMENT" ]; then
        echo "Rights: $RIGHTS_STATEMENT"
    fi
    echo "Max parallel jobs: $MAX_PARALLEL_JOBS"
    echo ""
    
    # Get all directories that need processing
    local -a directories=()
    directories+=(".")  # Include current directory
    
    # Find all subdirectories, excluding those in EXCLUDE_DIRS
    while IFS= read -r dir; do
        local skip=false
        local dir_basename=$(basename "$dir")
        
        # Always exclude .github and other dot directories
        if [[ "$dir_basename" == .* ]]; then
            skip=true
        fi
        
        # Check if directory should be excluded based on config
        if [ "$skip" = false ]; then
            for exclude in "${EXCLUDE_DIRS[@]}"; do
                if [[ "$dir_basename" == "$exclude" ]] || [[ "$dir" == *"/$exclude/"* ]]; then
                    skip=true
                    break
                fi
            done
        fi
        
        if [ "$skip" = false ]; then
            directories+=("$dir")
        fi
    done < <(find . -type d 2>/dev/null | grep -v '^\.$')
    
    echo "Found ${#directories[@]} directories to process"
    
    # Process directories in batches
    local total_files=0
    local processed_files=0
    
    # First count total files
    for dir in "${directories[@]}"; do
        local count=$(find "$dir" -maxdepth 1 -type f 2>/dev/null | wc -l)
        ((total_files += count))
    done
    
    echo "Total files to check: $total_files"
    echo ""
    
    # Check if there are any files to process
    if [ $total_files -eq 0 ]; then
        echo "No source files found to process in $repo_path"
        echo "This could mean:"
        echo "  - All files already have copyright headers"
        echo "  - No files match the configured extensions in sources.txt"
        echo "  - All files are in excluded directories"
        echo ""
        echo "✅ Copyright check completed successfully - no files needed processing"
        return 0
    fi
    
    # Process each directory's files in parallel
    for dir in "${directories[@]}"; do
        process_directory_files "$dir"
    done
    
    # Wait for all background jobs to complete
    echo ""
    echo "Waiting for all jobs to complete..."
    wait
    
    echo ""
    echo "Copyright headers processing completed for $repo_path!"
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
    # Parse command line options
    while [[ $# -gt 0 ]]; do
        case $1 in
            -j|--jobs)
                MAX_PARALLEL_JOBS="$2"
                shift 2
                ;;
            -h|--help)
                echo "Usage: $0 [options] [file]"
                echo ""
                echo "Options:"
                echo "  -j, --jobs N     Set maximum parallel jobs (default: 8)"
                echo "  -h, --help       Show this help message"
                echo ""
                echo "Examples:"
                echo "  $0                    Process all files in current repository"
                echo "  $0 -j 16              Process with 16 parallel jobs"
                echo "  $0 file.js            Process a single file"
                exit 0
                ;;
            *)
                # If it's a file, process it
                if [ -f "$1" ]; then
                    # Single file mode - used by GitHub Actions
                    add_copyright_header "$1"
                    exit 0
                fi
                shift
                ;;
        esac
    done
    
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