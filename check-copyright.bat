@echo off
setlocal enabledelayedexpansion

REM Copyright © Alexander Fields, 2025. All Rights Reserved. Created by Alexander Fields https://www.alexanderfields.me on 2025-07-08
REM Run copyright header check locally

REM Get the directory where this script is located
set "SCRIPT_DIR=%~dp0"

REM Change to the parent directory (project root)
cd /d "%SCRIPT_DIR%\.." || exit /b 1

echo Running copyright header check...

REM Capture the output and exit code
set "temp_output=%TEMP%\copyright_check_%RANDOM%.tmp"
call "%SCRIPT_DIR%add_copyright_headers.bat" >"%temp_output%" 2>&1
set "exit_code=%ERRORLEVEL%"

REM Display the output
type "%temp_output%"

REM Clean up temp file
del "%temp_output%" 2>nul

REM Check exit code first
if %exit_code% neq 0 (
    echo.
    echo ❌ Copyright header check failed with exit code: %exit_code%
    exit /b %exit_code%
)

REM Check for actual changes (excluding CopyrightAdder directory and check-copyright scripts)
set "has_changes=0"
for /f "tokens=*" %%i in ('git status --porcelain 2^>nul') do (
    set "line=%%i"
    echo !line! | findstr /v "^?? CopyrightAdder/" | findstr /v "^?? check-copyright\." >nul
    if not errorlevel 1 (
        set "has_changes=1"
    )
)

if !has_changes!==1 (
    echo.
    echo ⚠️  Copyright headers were added to some files.
    echo Please review the changes and commit them.
) else (
    echo.
    echo ✅ All files have proper copyright headers.
)

REM Always exit with success if we got here
exit /b 0