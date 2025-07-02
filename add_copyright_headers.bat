@echo off
setlocal enabledelayedexpansion

REM Universal Copyright Header Script for Windows
REM Automatically adds copyright headers with correct attribution based on git history
REM Works with any git repository

REM Configuration
if "%COMPANY_NAME%"=="" set COMPANY_NAME=Alexander
if "%RIGHTS_STATEMENT%"=="" set RIGHTS_STATEMENT=

REM Special authors configuration
set SPECIAL_AUTHORS[0]=roku674@gmail.com^|Alexander Fields^|https://www.alexanderfields.me
REM Add more special authors here

REM Check if we're in a git repository
git rev-parse --git-dir >nul 2>&1
if errorlevel 1 (
    echo Error: Not in a git repository!
    exit /b 1
)

echo Adding copyright headers based on git history...
echo Company: %COMPANY_NAME%
if not "%RIGHTS_STATEMENT%"=="" echo Rights: %RIGHTS_STATEMENT%
echo.

REM Process all source files
for /r . %%F in (*.c *.cc *.cpp *.cs *.java *.js *.jsx *.ts *.tsx *.go *.swift *.kt *.scala *.groovy *.dart *.rs *.py *.rb *.sh *.pl *.r *.jl *.nim *.cr *.ex *.exs *.sql *.lisp *.clj *.scm *.el) do (
    REM Skip certain directories
    echo %%F | findstr /i "node_modules .git dist build bin obj target .next .nuxt coverage __pycache__ .pytest_cache vendor packages .vs .vscode .idea" >nul
    if errorlevel 1 (
        REM Skip minified files
        echo %%F | findstr /i ".min.js .min.css" >nul
        if errorlevel 1 (
            call :process_file "%%F"
        )
    )
)

echo.
echo Copyright headers added successfully!
echo.
echo To customize this script:
echo   - Set COMPANY_NAME environment variable
echo   - Set RIGHTS_STATEMENT environment variable (e.g., "All Rights Reserved")
echo   - Edit SPECIAL_AUTHORS array in the script
goto :eof

:process_file
set "file=%~1"
set "filename=%~nx1"
set "ext=%~x1"
set "ext=!ext:.=!"

REM Determine comment style based on file extension
set "comment_style="
set "comment_end="

REM C-style comments
echo !ext! | findstr /i "c cc cpp cs java js jsx ts tsx go swift kt scala groovy dart rs" >nul
if not errorlevel 1 (
    set "comment_style=//"
    goto :got_style
)

REM Hash comments
echo !ext! | findstr /i "py rb sh bash zsh pl r jl nim cr ex exs yaml yml toml" >nul
if not errorlevel 1 (
    set "comment_style=#"
    goto :got_style
)

REM XML/HTML style
echo !ext! | findstr /i "xml html htm svg" >nul
if not errorlevel 1 (
    set "comment_style=<!--"
    set "comment_end= -->"
    goto :got_style
)

REM SQL style
if /i "!ext!"=="sql" (
    set "comment_style=--"
    goto :got_style
)

REM Lisp style
echo !ext! | findstr /i "lisp clj scm el" >nul
if not errorlevel 1 (
    set "comment_style=;;"
    goto :got_style
)

REM Unknown file type
echo Skipping unknown file type: %file%
goto :eof

:got_style
REM Get author info from git
set "author_info="
for /f "tokens=*" %%i in ('git log --diff-filter=A --follow --format="%%an^|%%ae^|%%ad" --date=format:"%%Y" -- "%file%" 2^>nul ^| tail -1') do set "author_info=%%i"

if "!author_info!"=="" (
    REM If file not in git history yet, use current git user
    for /f "tokens=*" %%i in ('git config user.name 2^>nul') do set "author_name=%%i"
    if "!author_name!"=="" set "author_name=Unknown"
    
    for /f "tokens=*" %%i in ('git config user.email 2^>nul') do set "author_email=%%i"
    if "!author_email!"=="" set "author_email=unknown@unknown.com"
    
    for /f "tokens=*" %%i in ('date /t') do set "year=%%i"
    set "year=!year:~-4!"
    
    set "author_info=!author_name!^|!author_email!^|!year!"
)

REM Parse author info
for /f "tokens=1,2,3 delims=|" %%a in ("!author_info!") do (
    set "author_name=%%a"
    set "author_email=%%b"
    set "year=%%c"
)

REM Format author with special handling
set "formatted_author=!author_name!"
call :format_author "!author_name!" "!author_email!"

REM Get last editor info from git
set "editor_info="
for /f "tokens=*" %%i in ('git log -1 --format="%%an^|%%ae^|%%ad" --date=format:"%%Y-%%m-%%d %%H:%%M:%%S" -- "%file%" 2^>nul') do set "editor_info=%%i"

if not "!editor_info!"=="" (
    REM Parse editor info
    for /f "tokens=1,2,3 delims=|" %%a in ("!editor_info!") do (
        set "editor_name=%%a"
        set "editor_email=%%b"
        set "editor_date=%%c"
    )
    
    REM Format editor with special handling
    set "formatted_editor=!editor_name!"
    call :format_author "!editor_name!" "!editor_email!"
    set "editor_name=!formatted_author!"
    set "formatted_author=!author_name!"
    call :format_author "!author_name!" "!author_email!"
)

REM Build the copyright header
if not "%RIGHTS_STATEMENT%"=="" (
    set "header=!comment_style! Copyright %COMPANY_NAME%, !year!. %RIGHTS_STATEMENT% Created by !formatted_author!!comment_end!"
) else (
    set "header=!comment_style! Copyright %COMPANY_NAME%, !year!. All Rights Reserved. Created by !formatted_author!!comment_end!"
)

REM Add edited by line if we have editor info and it's different from author
set "header2="
if not "!editor_info!"=="" (
    if not "!author_email!"=="!editor_email!" (
        set "header2=!comment_style! Edited by !editor_name! !editor_date!!comment_end!"
    )
)

REM Check if file already has a copyright header in the first 10 lines
set "has_copyright=0"
set "line_count=0"
for /f "tokens=*" %%i in ('type "%file%" 2^>nul') do (
    set /a line_count+=1
    if !line_count! leq 10 (
        echo %%i | findstr /c:"Copyright.*%COMPANY_NAME%" >nul
        if not errorlevel 1 set "has_copyright=1"
    )
)

REM Create temp file
set "temp_file=%TEMP%\copyright_temp_%RANDOM%.tmp"

if !has_copyright!==1 (
    echo File already has copyright header, updating: %file%
    
    REM Remove old copyright and edited lines and add new ones
    set "line_count=0"
    set "skip_line=0"
    
    REM Write the new headers
    echo !header!> "!temp_file!"
    if not "!header2!"=="" echo !header2!>> "!temp_file!"
    
    for /f "delims=" %%i in ('type "%file%"') do (
        set /a line_count+=1
        set "current_line=%%i"
        set "skip_line=0"
        
        if !line_count! leq 15 (
            REM Skip copyright lines
            echo %%i | findstr /c:"Copyright" >nul
            if not errorlevel 1 set "skip_line=1"
            
            REM Skip edited by lines
            echo %%i | findstr /c:"Edited by" >nul
            if not errorlevel 1 set "skip_line=1"
            
            if !skip_line!==0 (
                echo %%i>> "!temp_file!"
            )
        ) else (
            echo %%i>> "!temp_file!"
        )
    )
) else (
    REM Add new copyright header at the beginning
    echo !header!> "!temp_file!"
    if not "!header2!"=="" echo !header2!>> "!temp_file!"
    type "%file%" >> "!temp_file!" 2>nul
)

REM Replace original file
move /y "!temp_file!" "%file%" >nul

echo Processed: %file% ^(Author: !formatted_author!, Year: !year!^)
goto :eof

:format_author
set "auth_name=%~1"
set "auth_email=%~2"

REM Check if this is a special author
set "i=0"
:check_special_loop
if defined SPECIAL_AUTHORS[!i!] (
    for /f "tokens=1,2,3 delims=|" %%a in ("!SPECIAL_AUTHORS[%i%]!") do (
        if "!auth_email!"=="%%a" (
            if not "%%c"=="" (
                set "formatted_author=%%b %%c"
            ) else (
                set "formatted_author=%%b"
            )
            goto :eof
        )
        if "!auth_name!"=="%%b" (
            if not "%%c"=="" (
                set "formatted_author=%%b %%c"
            ) else (
                set "formatted_author=%%b"
            )
            goto :eof
        )
    )
    set /a i+=1
    goto :check_special_loop
)

goto :eof