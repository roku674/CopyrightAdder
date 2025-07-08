# Copyright © Alexander Fields, 2025. All Rights Reserved. Created by Alexander Fields https://www.alexanderfields.me on 2025-07-08
# Run copyright header check locally

# Get the directory where this script is located
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Change to the parent directory (project root)
Set-Location "$ScriptDir\.." -ErrorAction Stop

Write-Host "Running copyright header check..."

# Capture the output and exit code
$output = & "$ScriptDir\add_copyright_headers.ps1" 2>&1
$exitCode = $LASTEXITCODE

# Display the output
Write-Host $output

# Check exit code first
if ($exitCode -ne 0) {
    Write-Host ""
    Write-Host "❌ Copyright header check failed with exit code: $exitCode" -ForegroundColor Red
    exit $exitCode
}

# Check for actual changes (excluding CopyrightAdder directory and check-copyright.sh)
$changes = git status --porcelain | Where-Object { 
    $_ -notmatch "^\?\? CopyrightAdder/" -and 
    $_ -notmatch "^\?\? check-copyright\.(sh|ps1|bat)"
}

if ($changes) {
    Write-Host ""
    Write-Host "⚠️  Copyright headers were added to some files." -ForegroundColor Yellow
    Write-Host "Please review the changes and commit them."
} else {
    Write-Host ""
    Write-Host "✅ All files have proper copyright headers." -ForegroundColor Green
}

# Always exit with success if we got here
exit 0