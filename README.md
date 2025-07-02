# Universal Copyright Header Script

## Description
A reusable script that automatically adds copyright headers to source files based on git history. It correctly attributes each file to its original author by checking git logs. Available for bash (Linux/Mac), Windows batch, and PowerShell.

## Features
- **Automatic Author Detection**: Uses `git log` to find who created each file
- **Year Detection**: Gets the year from the first commit of each file
- **Multiple Language Support**: Supports 30+ programming languages with appropriate comment styles
- **JSON Support**: Adds copyright as a JSON property for .json files
- **Special Author Handling**: Can add website/contact info for specific authors
- **Smart Updates**: Updates existing copyright headers without duplicating
- **Exclusion Patterns**: Automatically excludes build artifacts, dependencies, and generated files
- **Customizable Rights Statement**: Add "All Rights Reserved" or other legal text
- **Cross-Platform**: Available for Linux/Mac (bash), Windows (batch), and PowerShell
- **Configuration File**: All settings now managed through a single `sources.txt` file

## Requirements

- Git repository (scripts use git history to determine authorship)
- One of: Bash (Linux/Mac), PowerShell (Windows), or Command Prompt (Windows)
- A `sources.txt` configuration file (see Configuration section)

## Quick Start

```bash
# 1. Clone or download the scripts
# 2. Create sources.txt with your configuration
echo "COMPANY_NAME=MyCompany" > sources.txt
echo "FILE_EXT_1=js" >> sources.txt
echo "FILE_EXT_2=py" >> sources.txt
echo "EXCLUDE_DIR_1=node_modules" >> sources.txt

# 3. Run the script
./add_copyright_headers.sh  # Linux/Mac
# OR
.\add_copyright_headers.ps1  # Windows PowerShell
# OR
add_copyright_headers.bat   # Windows Batch
```

## Migration from Environment Variables

**⚠️ IMPORTANT**: The scripts no longer use environment variables. If you were using the old version with environment variables like `COMPANY_NAME` or `RIGHTS_STATEMENT`, you must now create a `sources.txt` file with your configuration.

## Usage

1. Create a `sources.txt` file in the same directory as the scripts (see Configuration section below)
2. Run the appropriate script for your platform:

### Bash/Linux/Mac
```bash
./add_copyright_headers.sh
```

### Windows Batch
```cmd
add_copyright_headers.bat
```

### Windows PowerShell
```powershell
.\add_copyright_headers.ps1
```

## Configuration

**IMPORTANT**: All scripts now use a `sources.txt` configuration file instead of environment variables. The scripts will look for this file in:
1. The current working directory
2. The same directory as the script

If `sources.txt` is not found, the script will exit with an error.

### Creating sources.txt

Create a `sources.txt` file with the following format:

```
# Copyright Header Configuration File
# Company name for copyright
COMPANY_NAME=MyCompany

# Rights statement (leave empty for "All Rights Reserved")
RIGHTS_STATEMENT=All Rights Reserved

# Special authors with websites
# Format: email|name|website
SPECIAL_AUTHOR_1=email@example.com|Author Name|https://website.com
SPECIAL_AUTHOR_2=another@email.com|Another Author|

# Directories to exclude from processing
EXCLUDE_DIR_1=node_modules
EXCLUDE_DIR_2=.git
EXCLUDE_DIR_3=dist
EXCLUDE_DIR_4=build
EXCLUDE_DIR_5=bin
EXCLUDE_DIR_6=obj
EXCLUDE_DIR_7=target
EXCLUDE_DIR_8=.next
EXCLUDE_DIR_9=.nuxt
EXCLUDE_DIR_10=coverage
EXCLUDE_DIR_11=__pycache__
EXCLUDE_DIR_12=.pytest_cache
EXCLUDE_DIR_13=vendor
EXCLUDE_DIR_14=packages
EXCLUDE_DIR_15=.vs
EXCLUDE_DIR_16=.vscode
EXCLUDE_DIR_17=.idea

# File extensions to process (without the dot)
FILE_EXT_1=c
FILE_EXT_2=cc
FILE_EXT_3=cpp
FILE_EXT_4=cs
FILE_EXT_5=java
FILE_EXT_6=js
FILE_EXT_7=jsx
FILE_EXT_8=ts
FILE_EXT_9=tsx
FILE_EXT_10=go
FILE_EXT_11=swift
FILE_EXT_12=kt
FILE_EXT_13=scala
FILE_EXT_14=groovy
FILE_EXT_15=dart
FILE_EXT_16=rs
FILE_EXT_17=py
FILE_EXT_18=rb
FILE_EXT_19=sh
FILE_EXT_20=pl
FILE_EXT_21=r
FILE_EXT_22=jl
FILE_EXT_23=nim
FILE_EXT_24=cr
FILE_EXT_25=ex
FILE_EXT_26=exs
FILE_EXT_27=yaml
FILE_EXT_28=yml
FILE_EXT_29=toml
FILE_EXT_30=xml
FILE_EXT_31=html
FILE_EXT_32=htm
FILE_EXT_33=svg
FILE_EXT_34=sql
FILE_EXT_35=lisp
FILE_EXT_36=clj
FILE_EXT_37=scm
FILE_EXT_38=el
FILE_EXT_39=json
```

### Configuration Options

| Setting | Description | Format | Example |
|---------|-------------|--------|----------|
| `COMPANY_NAME` | Company name for copyright | Plain text | `COMPANY_NAME=MyCompany Inc.` |
| `RIGHTS_STATEMENT` | Optional rights text | Plain text | `RIGHTS_STATEMENT=All Rights Reserved` |
| `SPECIAL_AUTHOR_N` | Special author formatting | email\|name\|website | `SPECIAL_AUTHOR_1=john@example.com|John Doe|https://johndoe.com` |
| `EXCLUDE_DIR_N` | Directories to exclude | Directory name | `EXCLUDE_DIR_1=node_modules` |
| `FILE_EXT_N` | File extensions to process | Extension without dot | `FILE_EXT_1=js` |

**Notes:**
- The `_N` suffix should be replaced with sequential numbers (1, 2, 3, etc.)
- If `COMPANY_NAME` is not specified, it defaults to "Alexander"
- If `RIGHTS_STATEMENT` is empty, it defaults to "All Rights Reserved"
- For `SPECIAL_AUTHOR`, the website part is optional

### Comment Styles by File Type

The scripts automatically detect the appropriate comment style based on file extension:

| Comment Style | File Extensions |
|---------------|----------------|
| C-style (`//`) | .c, .cc, .cpp, .cs, .java, .js, .jsx, .ts, .tsx, .go, .swift, .kt, .scala, .groovy, .dart, .rs |
| Hash (`#`) | .py, .rb, .sh, .bash, .zsh, .pl, .r, .jl, .nim, .cr, .ex, .exs, .yaml, .yml, .toml |
| XML (`<!-- -->`) | .xml, .html, .htm, .svg |
| SQL (`--`) | .sql |
| Lisp (`;;`) | .lisp, .clj, .scm, .el |
| JSON (`"copyright": "..."`) | .json |

## Examples

### Output Format
```
//Copyright CompanyName, 2024, Written by John Doe
```

### With Rights Statement
```
//Copyright CompanyName, 2024. All Rights Reserved, Written by John Doe
```

### Special Author Output
```
//Copyright CompanyName, 2024, Written by John Doe https://johndoe.com
```

### Full Example with Rights Statement
```
//Copyright Perilous Games, Ltd., 2024. All Rights Reserved, Written by Alexander Fields https://www.alexanderfields.me
```

### JSON File Example
For JSON files, the copyright is added as a property:
```json
{
  "copyright": "Copyright MyCompany, 2024. All Rights Reserved. Created by John Doe",
  "name": "my-project",
  "version": "1.0.0"
}
```

With edited by info:
```json
{
  "copyright": "Copyright MyCompany, 2024. All Rights Reserved. Created by John Doe, Edited by Jane Smith 2024-01-15 10:30:00",
  "data": {}
}
```

## How It Works
1. Checks if current directory is a git repository
2. Finds all source files (excluding build artifacts)
3. For each file:
   - Gets original author from git history
   - Gets creation year from first commit
   - Formats copyright header based on file type
   - Adds or updates the copyright header

## Error Handling
- **Missing sources.txt**: Script exits with error and instructions
- **Not in git repository**: Script exits with error message
- **Files not in git history**: Uses current git user configuration
- **Unknown file types**: Skipped with message
- **Missing configuration values**: Uses sensible defaults

## Best Practices
- Run from repository root directory
- Commit changes before running to ensure clean git history
- Review changes after running (use `git diff`)
- Add script to .gitignore to avoid committing it

## Customization

### Adding New File Types
1. Edit `sources.txt` and add a new `FILE_EXT_N` entry
2. Make sure the file extension has a corresponding comment style in the script

### Adding Special Authors
1. Edit `sources.txt` and add `SPECIAL_AUTHOR_N` entries
2. Format: `email|name|optional_website`

### Excluding Additional Directories
1. Edit `sources.txt` and add `EXCLUDE_DIR_N` entries
2. Use directory names without paths

### Example sources.txt
```
# Company configuration
COMPANY_NAME=Acme Corp
RIGHTS_STATEMENT=All Rights Reserved

# Special authors
SPECIAL_AUTHOR_1=ceo@acme.com|Jane Smith|https://acme.com/team/jane
SPECIAL_AUTHOR_2=dev@acme.com|John Developer|

# Custom exclusions
EXCLUDE_DIR_1=node_modules
EXCLUDE_DIR_2=.git
EXCLUDE_DIR_3=my_custom_build_dir

# File types to process
FILE_EXT_1=js
FILE_EXT_2=py
FILE_EXT_3=java
```


## Troubleshooting

### "Error: sources.txt not found!"
- Make sure `sources.txt` exists in the current directory or the script directory
- Check file name spelling (it's case-sensitive on Linux/Mac)

### No files are being processed
- Check that you've added `FILE_EXT_N` entries to `sources.txt`
- Verify the file extensions match your source files (without the dot)
- Ensure you're running from the correct directory

### Copyright headers not appearing
- Verify the files are tracked in git (`git status`)
- Check that the file extension is configured in `sources.txt`
- Ensure the file type has a supported comment style

### Script runs but shows no output
- The script only outputs when it processes files
- Check that your exclude directories aren't filtering out all files
- Verify you have source files with configured extensions

If you like this bad boy checkout https://www.alexanderfields.me :D
