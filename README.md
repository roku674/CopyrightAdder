# Universal Copyright Header Script

## Description
A reusable bash script that automatically adds copyright headers to source files based on git history. It correctly attributes each file to its original author by checking git logs.

## Features
- **Automatic Author Detection**: Uses `git log` to find who created each file
- **Year Detection**: Gets the year from the first commit of each file
- **Multiple Language Support**: Supports 30+ programming languages with appropriate comment styles
- **Special Author Handling**: Can add website/contact info for specific authors
- **Smart Updates**: Updates existing copyright headers without duplicating
- **Exclusion Patterns**: Automatically excludes build artifacts, dependencies, and generated files

## Usage

### Basic Usage
```bash
./add_copyright_headers_proper.sh
```

### With Custom Company Name
```bash
COMPANY_NAME="MyCompany" ./add_copyright_headers_proper.sh
```

## Configuration

### Special Authors
Edit the `SPECIAL_AUTHORS` array in the script to add special formatting for specific contributors:
```bash
SPECIAL_AUTHORS=(
    "email@example.com|Author Name|https://website.com"
    "another@email.com|Another Author|"
)
```

### Supported File Types
- **C-style comments (//)**:  .c, .cc, .cpp, .cs, .java, .js, .jsx, .ts, .tsx, .go, .swift, .kt, .scala, .groovy, .dart, .rs
- **Hash comments (#)**: .py, .rb, .sh, .bash, .zsh, .pl, .r, .jl, .nim, .cr, .ex, .exs, .yaml, .yml, .toml
- **XML comments (<!-- -->)**: .xml, .html, .htm, .svg
- **SQL comments (--)**: .sql
- **Lisp comments (;;)**: .lisp, .clj, .scm, .el

### Excluded Directories
- node_modules, .git, dist, build, bin, obj, target
- .next, .nuxt, coverage, __pycache__, .pytest_cache
- vendor, packages, .vs, .vscode, .idea

## Examples

### Output Format
```
//Copyright CompanyName, 2024, Written by John Doe
```

### Special Author Output
```
//Copyright CompanyName, 2024, Written by John Doe https://johndoe.com
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
- Files not in git history use current git user
- Unknown file types are skipped
- Missing git repository shows error message

## Best Practices
- Run from repository root directory
- Commit changes before running to ensure clean git history
- Review changes after running (use `git diff`)
- Add script to .gitignore to avoid committing it

## Customization
To add support for new file types:
1. Add extension to `find_source_files` function
2. Add comment style to `add_copyright_header` case statement


If you like this bad boy checkout https://www.alexanderfields.me :D
