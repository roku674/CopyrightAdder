# Universal Copyright Header Script for Windows PowerShell
# Automatically adds copyright headers with correct attribution based on git history
# Works with any git repository

# Function to read configuration from sources.txt
function Read-Config {
    $configFile = "sources.txt"
    
    # Check if sources.txt exists in current directory
    if (-not (Test-Path $configFile)) {
        # Check if it exists in script directory
        $scriptDir = Split-Path -Parent $MyInvocation.ScriptName
        $configFile = Join-Path $scriptDir "sources.txt"
        
        if (-not (Test-Path $configFile)) {
            Write-Host "Error: sources.txt not found!" -ForegroundColor Red
            Write-Host "Please create a sources.txt file with configuration."
            exit 1
        }
    }
    
    # Initialize configuration
    $script:CompanyName = ""
    $script:RightsStatement = ""
    $script:SpecialAuthors = @()
    $script:ExcludeDirs = @()
    $script:FileExtensions = @()
    
    # Read configuration values
    Get-Content $configFile | ForEach-Object {
        $line = $_.Trim()
        
        # Skip comments and empty lines
        if ($line -match '^#' -or [string]::IsNullOrWhiteSpace($line)) {
            return
        }
        
        if ($line -match '^([^=]+)=(.*)$') {
            $key = $matches[1].Trim()
            $value = $matches[2].Trim()
            
            switch -Regex ($key) {
                '^COMPANY_NAME$' {
                    $script:CompanyName = $value
                }
                '^RIGHTS_STATEMENT$' {
                    $script:RightsStatement = $value
                }
                '^SPECIAL_AUTHOR_\d+$' {
                    if ($value) {
                        $parts = $value -split '\|'
                        if ($parts.Count -ge 2) {
                            $script:SpecialAuthors += @{
                                Email = $parts[0]
                                Name = $parts[1]
                                Website = if ($parts.Count -gt 2) { $parts[2] } else { "" }
                            }
                        }
                    }
                }
                '^EXCLUDE_DIR_\d+$' {
                    if ($value) {
                        $script:ExcludeDirs += $value
                    }
                }
                '^FILE_EXT_\d+$' {
                    if ($value) {
                        $script:FileExtensions += $value
                    }
                }
            }
        }
    }
    
    # Set defaults if not configured
    if (-not $script:CompanyName) {
        $script:CompanyName = "Alexander"
    }
}

# Load configuration
Read-Config

# Function to get author info from git
function Get-GitAuthorInfo {
    param([string]$FilePath)
    
    # Get the first commit that created this file with full timestamp
    $gitLog = git log --diff-filter=A --follow --format='%an|%ae|%ad' --date=format:'%Y|%Y-%m-%d %H:%M:%S' -- "$FilePath" 2>$null | Select-Object -Last 1
    
    if ([string]::IsNullOrEmpty($gitLog)) {
        # If file not in git history yet, use current git user
        $currentAuthor = git config user.name 2>$null
        if ([string]::IsNullOrEmpty($currentAuthor)) { $currentAuthor = "Unknown" }
        
        $currentEmail = git config user.email 2>$null
        if ([string]::IsNullOrEmpty($currentEmail)) { $currentEmail = "unknown@unknown.com" }
        
        $currentYear = Get-Date -Format "yyyy"
        $currentTimestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        
        return "$currentAuthor|$currentEmail|$currentYear|$currentTimestamp"
    }
    
    return $gitLog
}

# Function to format author with special handling
function Format-Author {
    param(
        [string]$AuthorName,
        [string]$AuthorEmail
    )
    
    # Check if this is a special author
    foreach ($special in $SpecialAuthors) {
        if ($AuthorEmail -eq $special.Email -or $AuthorName -eq $special.Name) {
            if ($special.Website) {
                return "$($special.Name) $($special.Website)"
            } else {
                return $special.Name
            }
        }
    }
    
    # Default format for other authors
    return $AuthorName
}

# Function to get comment style based on file extension
function Get-CommentStyle {
    param([string]$Extension)
    
    $extension = $Extension.TrimStart('.')
    
    # Define comment styles for different file types
    $commentStyles = @{
        # C-style comments
        "c" = @{ Start = "//"; End = "" }
        "cc" = @{ Start = "//"; End = "" }
        "cpp" = @{ Start = "//"; End = "" }
        "cs" = @{ Start = "//"; End = "" }
        "java" = @{ Start = "//"; End = "" }
        "js" = @{ Start = "//"; End = "" }
        "jsx" = @{ Start = "//"; End = "" }
        "ts" = @{ Start = "//"; End = "" }
        "tsx" = @{ Start = "//"; End = "" }
        "go" = @{ Start = "//"; End = "" }
        "swift" = @{ Start = "//"; End = "" }
        "kt" = @{ Start = "//"; End = "" }
        "scala" = @{ Start = "//"; End = "" }
        "groovy" = @{ Start = "//"; End = "" }
        "dart" = @{ Start = "//"; End = "" }
        "rs" = @{ Start = "//"; End = "" }
        
        # Hash comments
        "py" = @{ Start = "#"; End = "" }
        "rb" = @{ Start = "#"; End = "" }
        "sh" = @{ Start = "#"; End = "" }
        "bash" = @{ Start = "#"; End = "" }
        "zsh" = @{ Start = "#"; End = "" }
        "pl" = @{ Start = "#"; End = "" }
        "r" = @{ Start = "#"; End = "" }
        "jl" = @{ Start = "#"; End = "" }
        "nim" = @{ Start = "#"; End = "" }
        "cr" = @{ Start = "#"; End = "" }
        "ex" = @{ Start = "#"; End = "" }
        "exs" = @{ Start = "#"; End = "" }
        "yaml" = @{ Start = "#"; End = "" }
        "yml" = @{ Start = "#"; End = "" }
        "toml" = @{ Start = "#"; End = "" }
        
        # XML/HTML style
        "xml" = @{ Start = "<!--"; End = " -->" }
        "html" = @{ Start = "<!--"; End = " -->" }
        "htm" = @{ Start = "<!--"; End = " -->" }
        "svg" = @{ Start = "<!--"; End = " -->" }
        
        # SQL style
        "sql" = @{ Start = "--"; End = "" }
        
        # Lisp style
        "lisp" = @{ Start = ";;"; End = "" }
        "clj" = @{ Start = ";;"; End = "" }
        "scm" = @{ Start = ";;"; End = "" }
        "el" = @{ Start = ";;"; End = "" }
        
        # JSON - special handling
        "json" = @{ Start = "json_special"; End = "" }
    }
    
    return $commentStyles[$extension.ToLower()]
}

# Function to add copyright header to a file
function Add-CopyrightHeader {
    param([string]$FilePath)
    
    if (-not (Test-Path $FilePath)) {
        return
    }
    
    $extension = [System.IO.Path]::GetExtension($FilePath)
    $commentStyle = Get-CommentStyle -Extension $extension
    
    if (-not $commentStyle) {
        Write-Host "Skipping unknown file type: $FilePath"
        return
    }
    
    # Get author info from git
    $authorInfo = Get-GitAuthorInfo -FilePath $FilePath
    $parts = $authorInfo -split '\|'
    $authorName = $parts[0]
    $authorEmail = $parts[1]
    $yearAndTimestamp = $parts[2]
    
    # Parse year and timestamp
    $yearTimeParts = $yearAndTimestamp -split '\|'
    $year = $yearTimeParts[0]
    $creationTimestamp = if ($yearTimeParts.Count -gt 1) { $yearTimeParts[1] } else { Get-Date -Format "yyyy-MM-dd HH:mm:ss" }
    
    # Format the author
    $formattedAuthor = Format-Author -AuthorName $authorName -AuthorEmail $authorEmail
    
    # Get last editor info from git
    $editorLog = git log -1 --format='%an|%ae|%ad' --date=format:'%Y-%m-%d %H:%M:%S' -- "$FilePath" 2>$null
    $editorName = $null
    $editorEmail = $null
    $editorDate = $null
    $formattedEditor = $null
    
    if (-not [string]::IsNullOrEmpty($editorLog)) {
        $editorParts = $editorLog -split '\|'
        $editorName = $editorParts[0]
        $editorEmail = $editorParts[1]
        $editorDate = $editorParts[2]
        $formattedEditor = Format-Author -AuthorName $editorName -AuthorEmail $editorEmail
    }
    
    # Build the copyright text with creation timestamp from git
    if ($RightsStatement) {
        $copyrightText = "Copyright $CompanyName, $year. $RightsStatement Created by $formattedAuthor on $creationTimestamp"
    } else {
        $copyrightText = "Copyright $CompanyName, $year. All Rights Reserved. Created by $formattedAuthor on $creationTimestamp"
    }
    
    # Add edited by info if editor is different from author
    $editedText = ""
    if ($editorEmail -and $editorEmail -ne $authorEmail) {
        $editedText = "Edited by $formattedEditor $editorDate"
    }
    
    # Handle JSON files specially
    if ($commentStyle.Start -eq "json_special") {
        # For JSON files, we need to add/update the "copyright" key
        $content = Get-Content -Path $FilePath -Raw -ErrorAction SilentlyContinue
        
        if ($content) {
            try {
                $json = $content | ConvertFrom-Json
                $copyrightValue = $copyrightText
                if ($editedText) {
                    $copyrightValue += ", $editedText"
                }
                
                # Add or update copyright property
                if ($json.PSObject.Properties.Name -contains "copyright") {
                    Write-Host "File already has copyright key, updating: $FilePath"
                } else {
                    Write-Host "Adding copyright key to JSON: $FilePath"
                }
                
                $json | Add-Member -MemberType NoteProperty -Name "copyright" -Value $copyrightValue -Force
                
                # Convert back to JSON and save
                $newContent = $json | ConvertTo-Json -Depth 100
                # Ensure proper UTF-8 encoding without BOM
                Set-Content -Path $FilePath -Value $newContent -NoNewline -Encoding UTF8
            } catch {
                # If JSON parsing fails, try simple string manipulation
                if ($content -match '"copyright"\s*:\s*"[^"]*"') {
                    Write-Host "File already has copyright key, updating: $FilePath"
                    $copyrightValue = $copyrightText
                    if ($editedText) {
                        $copyrightValue += ", $editedText"
                    }
                    $newContent = $content -replace '"copyright"\s*:\s*"[^"]*"', "`"copyright`": `"$copyrightValue`""
                    Set-Content -Path $FilePath -Value $newContent -NoNewline -Encoding UTF8
                } else {
                    Write-Host "Adding copyright key to JSON: $FilePath"
                    # Try to add after opening brace
                    if ($content -match '^\s*\{') {
                        $copyrightValue = $copyrightText
                        if ($editedText) {
                            $copyrightValue += ", $editedText"
                        }
                        $newContent = $content -replace '^\s*\{', "{`r`n  `"copyright`": `"$copyrightValue`","
                        Set-Content -Path $FilePath -Value $newContent -NoNewline -Encoding UTF8
                    } else {
                        Write-Host "Warning: Could not parse JSON structure in $FilePath"
                        return
                    }
                }
            }
        } else {
            # Empty or new JSON file
            $copyrightValue = $copyrightText
            if ($editedText) {
                $copyrightValue += ", $editedText"
            }
            $newContent = @{copyright = $copyrightValue} | ConvertTo-Json
            Set-Content -Path $FilePath -Value $newContent -NoNewline -Encoding UTF8
        }
    } else {
        # Non-JSON files - use comment-based headers
        $header = "$($commentStyle.Start) $copyrightText$($commentStyle.End)"
        $headers = @($header)
        if ($editedText) {
            $headers += "$($commentStyle.Start) $editedText$($commentStyle.End)"
        }
        
        # Read file content
        $content = Get-Content -Path $FilePath -Raw -ErrorAction SilentlyContinue
        if (-not $content) {
            $content = ""
        }
        
        # Get first 10 lines to check for existing copyright
        $lines = $content -split "`r?`n"
        $first10Lines = $lines | Select-Object -First 10
        
        $hasCopyright = $false
        foreach ($line in $first10Lines) {
            if ($line -match "Copyright.*$([regex]::Escape($CompanyName))") {
                $hasCopyright = $true
                break
            }
        }
        
        if ($hasCopyright) {
            Write-Host "File already has copyright header, updating: $FilePath"
            
            # Remove old copyright and edited by lines
            $newLines = @()
            $lineCount = 0
            
            foreach ($line in $lines) {
                $lineCount++
                if ($lineCount -le 15) {
                    if ($line -match "Copyright" -or $line -match "Edited by") {
                        # Skip old copyright and edited by lines
                        continue
                    }
                }
                $newLines += $line
            }
            
            # Add new headers at the beginning
            $newContent = ($headers -join "`r`n") + "`r`n" + ($newLines -join "`r`n")
        } else {
            # Add new copyright headers at the beginning
            $newContent = ($headers -join "`r`n") + "`r`n" + $content
        }
        
        # Write back to file
        Set-Content -Path $FilePath -Value $newContent -NoNewline -Encoding UTF8
    }
    
    Write-Host "Processed: $FilePath (Author: $formattedAuthor, Year: $year)"
}

# Function to find all source files
function Find-SourceFiles {
    $files = @()
    
    # Build extension filters from config
    $extensions = $script:FileExtensions | ForEach-Object { "*.$_" }
    
    if ($extensions.Count -eq 0) {
        Write-Host "Warning: No file extensions configured in sources.txt" -ForegroundColor Yellow
        return $files
    }
    
    foreach ($ext in $extensions) {
        $foundFiles = Get-ChildItem -Path . -Filter $ext -Recurse -File -ErrorAction SilentlyContinue
        
        foreach ($file in $foundFiles) {
            $skip = $false
            
            # Check if file is in excluded directory
            foreach ($excludeDir in $script:ExcludeDirs) {
                # Check if the path contains the excluded directory at any level
                if ($file.FullName -match "[\\/]$([regex]::Escape($excludeDir))[\\/]") {
                    $skip = $true
                    break
                }
            }
            
            # Skip minified files
            if ($file.Name -match "\.min\.(js|css)$") {
                $skip = $true
            }
            
            # Skip migrations
            if ($file.FullName -match "migrations") {
                $skip = $true
            }
            
            if (-not $skip) {
                $files += $file
            }
        }
    }
    
    return $files
}

# Function to process a single git repository
function Process-SingleRepo {
    param([string]$RepoPath)
    
    Write-Host "Processing repository: $RepoPath"
    Write-Host "Company: $CompanyName"
    if ($RightsStatement) {
        Write-Host "Rights: $RightsStatement"
    }
    Write-Host ""
    
    # Process all source files
    $files = Find-SourceFiles
    
    foreach ($file in $files) {
        Add-CopyrightHeader -FilePath $file.FullName
    }
    
    Write-Host ""
    Write-Host "Copyright headers added successfully for $RepoPath!" -ForegroundColor Green
    Write-Host ""
}

# Function to find all git repositories recursively
function Find-GitRepos {
    param([string]$SearchPath = ".")
    
    Get-ChildItem -Path $SearchPath -Directory -Recurse -Force -ErrorAction SilentlyContinue |
        Where-Object { Test-Path (Join-Path $_.FullName ".git") } |
        Select-Object -ExpandProperty FullName
}

# Main execution
function Main {
    # Check if we're in a git repository
    $inGitRepo = $false
    try {
        git rev-parse --git-dir 2>&1 | Out-Null
        $inGitRepo = $true
    } catch {
        $inGitRepo = $false
    }
    
    if ($inGitRepo) {
        # Single repository mode
        Write-Host "Adding copyright headers based on git history..."
        Process-SingleRepo -RepoPath (Get-Location).Path
    } else {
        # Multi-repository mode
        Write-Host "Not in a git repository. Searching for git repositories recursively..."
        Write-Host ""
        
        $repos = Find-GitRepos -SearchPath "."
        
        if ($repos.Count -eq 0) {
            Write-Host "No git repositories found in the current directory tree." -ForegroundColor Red
            exit 1
        }
        
        Write-Host "Found $($repos.Count) git repositories. Processing..." -ForegroundColor Cyan
        Write-Host ("=" * 70)
        Write-Host ""
        
        $repoNumber = 0
        foreach ($repo in $repos) {
            $repoNumber++
            Write-Host "[$repoNumber/$($repos.Count)] Entering repository: $repo" -ForegroundColor Yellow
            Write-Host ("-" * 70)
            
            # Change to repository directory and process
            Push-Location $repo
            try {
                Process-SingleRepo -RepoPath $repo
            } finally {
                Pop-Location
            }
            
            Write-Host ("=" * 70)
            Write-Host ""
        }
        
        Write-Host "All repositories processed!" -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Host "To customize this script:"
    Write-Host "  - Edit sources.txt file in the script directory"
    Write-Host "  - Update COMPANY_NAME and RIGHTS_STATEMENT values"
    Write-Host "  - Add SPECIAL_AUTHOR entries for special author formatting"
    Write-Host "  - Add FILE_EXT entries for additional file types"
    Write-Host "  - Add EXCLUDE_DIR entries to skip directories"
}

# Run main function
Main