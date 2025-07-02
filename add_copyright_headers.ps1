# Universal Copyright Header Script for Windows PowerShell
# Automatically adds copyright headers with correct attribution based on git history
# Works with any git repository

param(
    [string]$CompanyName = $env:COMPANY_NAME ?? "Alexander",
    [string]$RightsStatement = $env:RIGHTS_STATEMENT ?? ""
)

# Special authors configuration
$SpecialAuthors = @(
    @{
        Email = "roku674@gmail.com"
        Name = "Alexander Fields"
        Website = "https://www.alexanderfields.me"
    }
    # Add more special authors here
)

# Function to get author info from git
function Get-GitAuthorInfo {
    param([string]$FilePath)
    
    # Get the first commit that created this file
    $gitLog = git log --diff-filter=A --follow --format='%an|%ae|%ad' --date=format:'%Y' -- "$FilePath" 2>$null | Select-Object -Last 1
    
    if ([string]::IsNullOrEmpty($gitLog)) {
        # If file not in git history yet, use current git user
        $currentAuthor = git config user.name 2>$null
        if ([string]::IsNullOrEmpty($currentAuthor)) { $currentAuthor = "Unknown" }
        
        $currentEmail = git config user.email 2>$null
        if ([string]::IsNullOrEmpty($currentEmail)) { $currentEmail = "unknown@unknown.com" }
        
        $currentYear = Get-Date -Format "yyyy"
        
        return "$currentAuthor|$currentEmail|$currentYear"
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
    $year = $parts[2]
    
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
    
    # Build the copyright header
    if ($RightsStatement) {
        $header = "$($commentStyle.Start) Copyright $CompanyName, $year. $RightsStatement Created by $formattedAuthor$($commentStyle.End)"
    } else {
        $header = "$($commentStyle.Start) Copyright $CompanyName, $year. All Rights Reserved. Created by $formattedAuthor$($commentStyle.End)"
    }
    
    # Add edited by line if editor is different from author
    $headers = @($header)
    if ($editorEmail -and $editorEmail -ne $authorEmail) {
        $headers += "$($commentStyle.Start) Edited by $formattedEditor $editorDate$($commentStyle.End)"
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
    Set-Content -Path $FilePath -Value $newContent -NoNewline
    
    Write-Host "Processed: $FilePath (Author: $formattedAuthor, Year: $year)"
}

# Function to find all source files
function Find-SourceFiles {
    $excludeDirs = @(
        "node_modules",
        ".git",
        "dist",
        "build",
        "bin",
        "obj",
        "target",
        ".next",
        ".nuxt",
        "coverage",
        "__pycache__",
        ".pytest_cache",
        "vendor",
        "packages",
        ".vs",
        ".vscode",
        ".idea"
    )
    
    $extensions = @(
        "*.c", "*.cc", "*.cpp", "*.cs",
        "*.java", "*.js", "*.jsx", "*.ts", "*.tsx",
        "*.go", "*.swift", "*.kt", "*.scala", "*.groovy",
        "*.dart", "*.rs", "*.py", "*.rb", "*.sh",
        "*.pl", "*.r", "*.jl", "*.nim", "*.cr",
        "*.ex", "*.exs", "*.sql", "*.lisp", "*.clj",
        "*.scm", "*.el"
    )
    
    $files = @()
    
    foreach ($ext in $extensions) {
        $foundFiles = Get-ChildItem -Path . -Filter $ext -Recurse -File -ErrorAction SilentlyContinue
        
        foreach ($file in $foundFiles) {
            $skip = $false
            
            # Check if file is in excluded directory
            foreach ($excludeDir in $excludeDirs) {
                if ($file.FullName -match [regex]::Escape($excludeDir)) {
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

# Main execution
function Main {
    # Check if we're in a git repository
    try {
        git rev-parse --git-dir | Out-Null
    } catch {
        Write-Host "Error: Not in a git repository!" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "Adding copyright headers based on git history..."
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
    Write-Host "Copyright headers added successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "To customize this script:"
    Write-Host "  - Set COMPANY_NAME environment variable or use -CompanyName parameter"
    Write-Host "  - Set RIGHTS_STATEMENT environment variable or use -RightsStatement parameter"
    Write-Host "  - Edit `$SpecialAuthors array in the script"
    Write-Host "  - Add more file extensions in Find-SourceFiles function"
}

# Run main function
Main