@echo off
setlocal enabledelayedexpansion

REM Universal Copyright Header Script for Windows
REM Automatically adds copyright headers with correct attribution based on git history
REM Works with any git repository

REM Load configuration from sources.txt
call :load_config
if errorlevel 1 exit /b 1

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

REM Process all source files based on configuration
call :process_all_files

echo.
echo Copyright headers added successfully!
echo.
echo To customize this script:
echo   - Edit sources.txt file in the script directory
echo   - Update COMPANY_NAME and RIGHTS_STATEMENT values
echo   - Add SPECIAL_AUTHOR entries for special author formatting
echo   - Add FILE_EXT entries for additional file types
echo   - Add EXCLUDE_DIR entries to skip directories
goto :eof

:load_config
REM Find sources.txt
set "config_file=sources.txt"
if not exist "%config_file%" (
    REM Check in script directory
    set "config_file=%~dp0sources.txt"
    if not exist "!config_file!" (
        echo Error: sources.txt not found!
        echo Please create a sources.txt file with configuration.
        exit /b 1
    )
)

REM Initialize variables
set "COMPANY_NAME="
set "RIGHTS_STATEMENT="
set "special_count=0"
set "exclude_count=0"
set "ext_count=0"

REM Read configuration
for /f "tokens=1,* delims==" %%a in ('type "%config_file%" ^| findstr /v "^#" ^| findstr /v "^$"') do (
    set "key=%%a"
    set "value=%%b"
    
    REM Trim spaces
    for /f "tokens=* delims= " %%c in ("!key!") do set "key=%%c"
    for /f "tokens=* delims= " %%c in ("!value!") do set "value=%%c"
    
    if "!key!"=="COMPANY_NAME" set "COMPANY_NAME=!value!"
    if "!key!"=="RIGHTS_STATEMENT" set "RIGHTS_STATEMENT=!value!"
    
    REM Special authors
    echo !key! | findstr /b "SPECIAL_AUTHOR_" >nul
    if not errorlevel 1 (
        if not "!value!"=="" (
            set "SPECIAL_AUTHORS[!special_count!]=!value!"
            set /a special_count+=1
        )
    )
    
    REM Exclude directories
    echo !key! | findstr /b "EXCLUDE_DIR_" >nul
    if not errorlevel 1 (
        if not "!value!"=="" (
            set "EXCLUDE_DIRS[!exclude_count!]=!value!"
            set /a exclude_count+=1
        )
    )
    
    REM File extensions
    echo !key! | findstr /b "FILE_EXT_" >nul
    if not errorlevel 1 (
        if not "!value!"=="" (
            set "FILE_EXTS[!ext_count!]=!value!"
            set /a ext_count+=1
        )
    )
)

REM Set defaults if not configured
if "!COMPANY_NAME!"=="" set "COMPANY_NAME=Alexander"

goto :eof

:process_all_files
REM Build file pattern list
set "file_patterns="
for /l %%i in (0,1,%ext_count%) do (
    if defined FILE_EXTS[%%i] (
        set "file_patterns=!file_patterns! *.!FILE_EXTS[%%i]!"
    )
)

REM Process files with each extension
for /l %%i in (0,1,%ext_count%) do (
    if defined FILE_EXTS[%%i] (
        for /r . %%F in (*.!FILE_EXTS[%%i]!) do (
            set "skip_file=0"
            
            REM Check exclude directories
            for /l %%j in (0,1,%exclude_count%) do (
                if defined EXCLUDE_DIRS[%%j] (
                    echo %%F | findstr /i "!EXCLUDE_DIRS[%%j]!" >nul
                    if not errorlevel 1 set "skip_file=1"
                )
            )
            
            REM Skip minified files
            echo %%F | findstr /i ".min.js .min.css" >nul
            if not errorlevel 1 set "skip_file=1"
            
            REM Skip migrations
            echo %%F | findstr /i "migrations" >nul
            if not errorlevel 1 set "skip_file=1"
            
            if !skip_file!==0 (
                call :process_file "%%F"
            )
        )
    )
)

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

REM JSON style
if /i "!ext!"=="json" (
    set "comment_style=json_special"
    goto :got_style
)

REM Unknown file type
echo Skipping unknown file type: %file%
goto :eof

:load_config
REM Find sources.txt
set "config_file=sources.txt"
if not exist "%config_file%" (
    REM Check in script directory
    set "config_file=%~dp0sources.txt"
    if not exist "!config_file!" (
        echo Error: sources.txt not found!
        echo Please create a sources.txt file with configuration.
        exit /b 1
    )
)

REM Initialize variables
set "COMPANY_NAME="
set "RIGHTS_STATEMENT="
set "special_count=0"
set "exclude_count=0"
set "ext_count=0"

REM Read configuration
for /f "tokens=1,* delims==" %%a in ('type "%config_file%" ^| findstr /v "^#" ^| findstr /v "^$"') do (
    set "key=%%a"
    set "value=%%b"
    
    REM Trim spaces
    for /f "tokens=* delims= " %%c in ("!key!") do set "key=%%c"
    for /f "tokens=* delims= " %%c in ("!value!") do set "value=%%c"
    
    if "!key!"=="COMPANY_NAME" set "COMPANY_NAME=!value!"
    if "!key!"=="RIGHTS_STATEMENT" set "RIGHTS_STATEMENT=!value!"
    
    REM Special authors
    echo !key! | findstr /b "SPECIAL_AUTHOR_" >nul
    if not errorlevel 1 (
        if not "!value!"=="" (
            set "SPECIAL_AUTHORS[!special_count!]=!value!"
            set /a special_count+=1
        )
    )
    
    REM Exclude directories
    echo !key! | findstr /b "EXCLUDE_DIR_" >nul
    if not errorlevel 1 (
        if not "!value!"=="" (
            set "EXCLUDE_DIRS[!exclude_count!]=!value!"
            set /a exclude_count+=1
        )
    )
    
    REM File extensions
    echo !key! | findstr /b "FILE_EXT_" >nul
    if not errorlevel 1 (
        if not "!value!"=="" (
            set "FILE_EXTS[!ext_count!]=!value!"
            set /a ext_count+=1
        )
    )
)

REM Set defaults if not configured
if "!COMPANY_NAME!"=="" set "COMPANY_NAME=Alexander"

goto :eof

:process_all_files
REM Build file pattern list
set "file_patterns="
for /l %%i in (0,1,%ext_count%) do (
    if defined FILE_EXTS[%%i] (
        set "file_patterns=!file_patterns! *.!FILE_EXTS[%%i]!"
    )
)

REM Process files with each extension
for /l %%i in (0,1,%ext_count%) do (
    if defined FILE_EXTS[%%i] (
        for /r . %%F in (*.!FILE_EXTS[%%i]!) do (
            set "skip_file=0"
            
            REM Check exclude directories
            for /l %%j in (0,1,%exclude_count%) do (
                if defined EXCLUDE_DIRS[%%j] (
                    echo %%F | findstr /i "!EXCLUDE_DIRS[%%j]!" >nul
                    if not errorlevel 1 set "skip_file=1"
                )
            )
            
            REM Skip minified files
            echo %%F | findstr /i ".min.js .min.css" >nul
            if not errorlevel 1 set "skip_file=1"
            
            REM Skip migrations
            echo %%F | findstr /i "migrations" >nul
            if not errorlevel 1 set "skip_file=1"
            
            if !skip_file!==0 (
                call :process_file "%%F"
            )
        )
    )
)

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

REM Get current timestamp using WMIC for consistent format
for /f "tokens=2 delims==" %%a in ('wmic OS Get localdatetime /value') do set "dt=%%a"
set "timestamp=!dt:~0,4!-!dt:~4,2!-!dt:~6,2! !dt:~8,2!:!dt:~10,2!:!dt:~12,2!"

REM Build the copyright text
if not "%RIGHTS_STATEMENT%"=="" (
    set "copyright_text=Copyright %COMPANY_NAME%, !year!. %RIGHTS_STATEMENT% Created by !formatted_author! on !timestamp!"
) else (
    set "copyright_text=Copyright %COMPANY_NAME%, !year!. All Rights Reserved. Created by !formatted_author! on !timestamp!"
)

REM Add edited by info if we have editor info and it's different from author
set "edited_text="
if not "!editor_info!"=="" (
    if not "!author_email!"=="!editor_email!" (
        set "edited_text=Edited by !editor_name! !editor_date!"
    )
)

REM Handle JSON files specially
if "!comment_style!"=="json_special" (
    REM For JSON files, add/update copyright key
    set "has_copyright=0"
    
    REM Check if file has copyright key
    findstr /c:"\"copyright\"" "%file%" >nul 2>&1
    if not errorlevel 1 set "has_copyright=1"
    
    set "temp_file=%TEMP%\copyright_temp_%RANDOM%.tmp"
    
    REM Combine copyright and edited text
    set "copyright_value=!copyright_text!"
    if not "!edited_text!"=="" (
        set "copyright_value=!copyright_value!, !edited_text!"
    )
    
    REM Escape quotes for PowerShell
    set "copyright_value_escaped=!copyright_value!"
    
    if !has_copyright!==1 (
        echo File already has copyright key, updating: %file%
        REM Use PowerShell to update JSON properly
        powershell -NoProfile -Command "& {$json = Get-Content '%file%' -Raw; $json = $json -replace '\"copyright\"[^,}]*[,]?', '\"copyright\": \"!copyright_value_escaped!\",'; $json | Set-Content '!temp_file!' -NoNewline}" 2>nul
        if errorlevel 1 (
            REM If PowerShell fails, do simple text replacement
            type "%file%" > "!temp_file!"
        )
    ) else (
        echo Adding copyright key to JSON: %file%
        REM Use PowerShell to add copyright key
        powershell -NoProfile -Command "& {$content = Get-Content '%file%' -Raw; if ($content -match '^\s*\{') {$content = $content -replace '^\s*\{', \"{`n  `\"copyright`\": `\"!copyright_value_escaped!`\",\"}; $content | Set-Content '!temp_file!' -NoNewline}" 2>nul
        if errorlevel 1 (
            REM If PowerShell fails, create simple JSON
            (
                echo {
                echo   "copyright": "!copyright_value!",
                echo   "note": "file processed"
                echo }
            ) > "!temp_file!"
        )
    )
    
    REM Replace original file
    move /y "!temp_file!" "%file%" >nul
) else (
    REM Non-JSON files - use comment headers
    set "header=!comment_style! !copyright_text!!comment_end!"
    set "header2="
    if not "!edited_text!"=="" (
        set "header2=!comment_style! !edited_text!!comment_end!"
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
        (echo.!header!) > "!temp_file!"
        if not "!header2!"=="" (echo.!header2!) >> "!temp_file!"
        
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
                    (echo.%%i) >> "!temp_file!"
                )
            ) else (
                (echo.%%i) >> "!temp_file!"
            )
        )
    ) else (
        REM Add new copyright header at the beginning
        (echo.!header!) > "!temp_file!"
        if not "!header2!"=="" (echo.!header2!) >> "!temp_file!"
        type "%file%" >> "!temp_file!" 2>nul
    )
    
    REM Replace original file
    move /y "!temp_file!" "%file%" >nul
)

echo Processed: %file% ^(Author: !formatted_author!, Year: !year!^)
goto :eof

:load_config
REM Find sources.txt
set "config_file=sources.txt"
if not exist "%config_file%" (
    REM Check in script directory
    set "config_file=%~dp0sources.txt"
    if not exist "!config_file!" (
        echo Error: sources.txt not found!
        echo Please create a sources.txt file with configuration.
        exit /b 1
    )
)

REM Initialize variables
set "COMPANY_NAME="
set "RIGHTS_STATEMENT="
set "special_count=0"
set "exclude_count=0"
set "ext_count=0"

REM Read configuration
for /f "tokens=1,* delims==" %%a in ('type "%config_file%" ^| findstr /v "^#" ^| findstr /v "^$"') do (
    set "key=%%a"
    set "value=%%b"
    
    REM Trim spaces
    for /f "tokens=* delims= " %%c in ("!key!") do set "key=%%c"
    for /f "tokens=* delims= " %%c in ("!value!") do set "value=%%c"
    
    if "!key!"=="COMPANY_NAME" set "COMPANY_NAME=!value!"
    if "!key!"=="RIGHTS_STATEMENT" set "RIGHTS_STATEMENT=!value!"
    
    REM Special authors
    echo !key! | findstr /b "SPECIAL_AUTHOR_" >nul
    if not errorlevel 1 (
        if not "!value!"=="" (
            set "SPECIAL_AUTHORS[!special_count!]=!value!"
            set /a special_count+=1
        )
    )
    
    REM Exclude directories
    echo !key! | findstr /b "EXCLUDE_DIR_" >nul
    if not errorlevel 1 (
        if not "!value!"=="" (
            set "EXCLUDE_DIRS[!exclude_count!]=!value!"
            set /a exclude_count+=1
        )
    )
    
    REM File extensions
    echo !key! | findstr /b "FILE_EXT_" >nul
    if not errorlevel 1 (
        if not "!value!"=="" (
            set "FILE_EXTS[!ext_count!]=!value!"
            set /a ext_count+=1
        )
    )
)

REM Set defaults if not configured
if "!COMPANY_NAME!"=="" set "COMPANY_NAME=Alexander"

goto :eof

:process_all_files
REM Build file pattern list
set "file_patterns="
for /l %%i in (0,1,%ext_count%) do (
    if defined FILE_EXTS[%%i] (
        set "file_patterns=!file_patterns! *.!FILE_EXTS[%%i]!"
    )
)

REM Process files with each extension
for /l %%i in (0,1,%ext_count%) do (
    if defined FILE_EXTS[%%i] (
        for /r . %%F in (*.!FILE_EXTS[%%i]!) do (
            set "skip_file=0"
            
            REM Check exclude directories
            for /l %%j in (0,1,%exclude_count%) do (
                if defined EXCLUDE_DIRS[%%j] (
                    echo %%F | findstr /i "!EXCLUDE_DIRS[%%j]!" >nul
                    if not errorlevel 1 set "skip_file=1"
                )
            )
            
            REM Skip minified files
            echo %%F | findstr /i ".min.js .min.css" >nul
            if not errorlevel 1 set "skip_file=1"
            
            REM Skip migrations
            echo %%F | findstr /i "migrations" >nul
            if not errorlevel 1 set "skip_file=1"
            
            if !skip_file!==0 (
                call :process_file "%%F"
            )
        )
    )
)

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

:load_config
REM Find sources.txt
set "config_file=sources.txt"
if not exist "%config_file%" (
    REM Check in script directory
    set "config_file=%~dp0sources.txt"
    if not exist "!config_file!" (
        echo Error: sources.txt not found!
        echo Please create a sources.txt file with configuration.
        exit /b 1
    )
)

REM Initialize variables
set "COMPANY_NAME="
set "RIGHTS_STATEMENT="
set "special_count=0"
set "exclude_count=0"
set "ext_count=0"

REM Read configuration
for /f "tokens=1,* delims==" %%a in ('type "%config_file%" ^| findstr /v "^#" ^| findstr /v "^$"') do (
    set "key=%%a"
    set "value=%%b"
    
    REM Trim spaces
    for /f "tokens=* delims= " %%c in ("!key!") do set "key=%%c"
    for /f "tokens=* delims= " %%c in ("!value!") do set "value=%%c"
    
    if "!key!"=="COMPANY_NAME" set "COMPANY_NAME=!value!"
    if "!key!"=="RIGHTS_STATEMENT" set "RIGHTS_STATEMENT=!value!"
    
    REM Special authors
    echo !key! | findstr /b "SPECIAL_AUTHOR_" >nul
    if not errorlevel 1 (
        if not "!value!"=="" (
            set "SPECIAL_AUTHORS[!special_count!]=!value!"
            set /a special_count+=1
        )
    )
    
    REM Exclude directories
    echo !key! | findstr /b "EXCLUDE_DIR_" >nul
    if not errorlevel 1 (
        if not "!value!"=="" (
            set "EXCLUDE_DIRS[!exclude_count!]=!value!"
            set /a exclude_count+=1
        )
    )
    
    REM File extensions
    echo !key! | findstr /b "FILE_EXT_" >nul
    if not errorlevel 1 (
        if not "!value!"=="" (
            set "FILE_EXTS[!ext_count!]=!value!"
            set /a ext_count+=1
        )
    )
)

REM Set defaults if not configured
if "!COMPANY_NAME!"=="" set "COMPANY_NAME=Alexander"

goto :eof

:process_all_files
REM Build file pattern list
set "file_patterns="
for /l %%i in (0,1,%ext_count%) do (
    if defined FILE_EXTS[%%i] (
        set "file_patterns=!file_patterns! *.!FILE_EXTS[%%i]!"
    )
)

REM Process files with each extension
for /l %%i in (0,1,%ext_count%) do (
    if defined FILE_EXTS[%%i] (
        for /r . %%F in (*.!FILE_EXTS[%%i]!) do (
            set "skip_file=0"
            
            REM Check exclude directories
            for /l %%j in (0,1,%exclude_count%) do (
                if defined EXCLUDE_DIRS[%%j] (
                    echo %%F | findstr /i "!EXCLUDE_DIRS[%%j]!" >nul
                    if not errorlevel 1 set "skip_file=1"
                )
            )
            
            REM Skip minified files
            echo %%F | findstr /i ".min.js .min.css" >nul
            if not errorlevel 1 set "skip_file=1"
            
            REM Skip migrations
            echo %%F | findstr /i "migrations" >nul
            if not errorlevel 1 set "skip_file=1"
            
            if !skip_file!==0 (
                call :process_file "%%F"
            )
        )
    )
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

:load_config
REM Find sources.txt
set "config_file=sources.txt"
if not exist "%config_file%" (
    REM Check in script directory
    set "config_file=%~dp0sources.txt"
    if not exist "!config_file!" (
        echo Error: sources.txt not found!
        echo Please create a sources.txt file with configuration.
        exit /b 1
    )
)

REM Initialize variables
set "COMPANY_NAME="
set "RIGHTS_STATEMENT="
set "special_count=0"
set "exclude_count=0"
set "ext_count=0"

REM Read configuration
for /f "tokens=1,* delims==" %%a in ('type "%config_file%" ^| findstr /v "^#" ^| findstr /v "^$"') do (
    set "key=%%a"
    set "value=%%b"
    
    REM Trim spaces
    for /f "tokens=* delims= " %%c in ("!key!") do set "key=%%c"
    for /f "tokens=* delims= " %%c in ("!value!") do set "value=%%c"
    
    if "!key!"=="COMPANY_NAME" set "COMPANY_NAME=!value!"
    if "!key!"=="RIGHTS_STATEMENT" set "RIGHTS_STATEMENT=!value!"
    
    REM Special authors
    echo !key! | findstr /b "SPECIAL_AUTHOR_" >nul
    if not errorlevel 1 (
        if not "!value!"=="" (
            set "SPECIAL_AUTHORS[!special_count!]=!value!"
            set /a special_count+=1
        )
    )
    
    REM Exclude directories
    echo !key! | findstr /b "EXCLUDE_DIR_" >nul
    if not errorlevel 1 (
        if not "!value!"=="" (
            set "EXCLUDE_DIRS[!exclude_count!]=!value!"
            set /a exclude_count+=1
        )
    )
    
    REM File extensions
    echo !key! | findstr /b "FILE_EXT_" >nul
    if not errorlevel 1 (
        if not "!value!"=="" (
            set "FILE_EXTS[!ext_count!]=!value!"
            set /a ext_count+=1
        )
    )
)

REM Set defaults if not configured
if "!COMPANY_NAME!"=="" set "COMPANY_NAME=Alexander"

goto :eof

:process_all_files
REM Build file pattern list
set "file_patterns="
for /l %%i in (0,1,%ext_count%) do (
    if defined FILE_EXTS[%%i] (
        set "file_patterns=!file_patterns! *.!FILE_EXTS[%%i]!"
    )
)

REM Process files with each extension
for /l %%i in (0,1,%ext_count%) do (
    if defined FILE_EXTS[%%i] (
        for /r . %%F in (*.!FILE_EXTS[%%i]!) do (
            set "skip_file=0"
            
            REM Check exclude directories
            for /l %%j in (0,1,%exclude_count%) do (
                if defined EXCLUDE_DIRS[%%j] (
                    echo %%F | findstr /i "!EXCLUDE_DIRS[%%j]!" >nul
                    if not errorlevel 1 set "skip_file=1"
                )
            )
            
            REM Skip minified files
            echo %%F | findstr /i ".min.js .min.css" >nul
            if not errorlevel 1 set "skip_file=1"
            
            REM Skip migrations
            echo %%F | findstr /i "migrations" >nul
            if not errorlevel 1 set "skip_file=1"
            
            if !skip_file!==0 (
                call :process_file "%%F"
            )
        )
    )
)

goto :eof
        )
    )
    set /a i+=1
    goto :check_special_loop
)

goto :eof

:load_config
REM Find sources.txt
set "config_file=sources.txt"
if not exist "%config_file%" (
    REM Check in script directory
    set "config_file=%~dp0sources.txt"
    if not exist "!config_file!" (
        echo Error: sources.txt not found!
        echo Please create a sources.txt file with configuration.
        exit /b 1
    )
)

REM Initialize variables
set "COMPANY_NAME="
set "RIGHTS_STATEMENT="
set "special_count=0"
set "exclude_count=0"
set "ext_count=0"

REM Read configuration
for /f "tokens=1,* delims==" %%a in ('type "%config_file%" ^| findstr /v "^#" ^| findstr /v "^$"') do (
    set "key=%%a"
    set "value=%%b"
    
    REM Trim spaces
    for /f "tokens=* delims= " %%c in ("!key!") do set "key=%%c"
    for /f "tokens=* delims= " %%c in ("!value!") do set "value=%%c"
    
    if "!key!"=="COMPANY_NAME" set "COMPANY_NAME=!value!"
    if "!key!"=="RIGHTS_STATEMENT" set "RIGHTS_STATEMENT=!value!"
    
    REM Special authors
    echo !key! | findstr /b "SPECIAL_AUTHOR_" >nul
    if not errorlevel 1 (
        if not "!value!"=="" (
            set "SPECIAL_AUTHORS[!special_count!]=!value!"
            set /a special_count+=1
        )
    )
    
    REM Exclude directories
    echo !key! | findstr /b "EXCLUDE_DIR_" >nul
    if not errorlevel 1 (
        if not "!value!"=="" (
            set "EXCLUDE_DIRS[!exclude_count!]=!value!"
            set /a exclude_count+=1
        )
    )
    
    REM File extensions
    echo !key! | findstr /b "FILE_EXT_" >nul
    if not errorlevel 1 (
        if not "!value!"=="" (
            set "FILE_EXTS[!ext_count!]=!value!"
            set /a ext_count+=1
        )
    )
)

REM Set defaults if not configured
if "!COMPANY_NAME!"=="" set "COMPANY_NAME=Alexander"

goto :eof

:process_all_files
REM Build file pattern list
set "file_patterns="
for /l %%i in (0,1,%ext_count%) do (
    if defined FILE_EXTS[%%i] (
        set "file_patterns=!file_patterns! *.!FILE_EXTS[%%i]!"
    )
)

REM Process files with each extension
for /l %%i in (0,1,%ext_count%) do (
    if defined FILE_EXTS[%%i] (
        for /r . %%F in (*.!FILE_EXTS[%%i]!) do (
            set "skip_file=0"
            
            REM Check exclude directories
            for /l %%j in (0,1,%exclude_count%) do (
                if defined EXCLUDE_DIRS[%%j] (
                    echo %%F | findstr /i "!EXCLUDE_DIRS[%%j]!" >nul
                    if not errorlevel 1 set "skip_file=1"
                )
            )
            
            REM Skip minified files
            echo %%F | findstr /i ".min.js .min.css" >nul
            if not errorlevel 1 set "skip_file=1"
            
            REM Skip migrations
            echo %%F | findstr /i "migrations" >nul
            if not errorlevel 1 set "skip_file=1"
            
            if !skip_file!==0 (
                call :process_file "%%F"
            )
        )
    )
)

goto :eof