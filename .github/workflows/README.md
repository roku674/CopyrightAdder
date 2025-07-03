# Copyright Header GitHub Action

This GitHub Action automatically adds copyright headers to new and modified files in pull requests.

## How it works

1. **Triggers on Pull Requests**: The action runs when a PR is opened, synchronized, or reopened
2. **Detects Changed Files**: Uses `tj-actions/changed-files` to identify modified source files
3. **Adds Copyright Headers**: Runs the CopyrightAdder script on each changed file
4. **Commits Changes**: If headers were added, commits them back to the PR branch
5. **Comments on PR**: Notifies that copyright headers have been added

## Supported File Types

The action supports 40+ programming languages and file types, including:
- Java, JavaScript, TypeScript, C/C++, C#, Python, Go, Rust
- Ruby, PHP, Swift, Kotlin, Scala, Clojure
- Shell scripts, PowerShell, YAML, JSON, XML, HTML
- And many more...

## Configuration

The copyright header format is controlled by `CopyrightAdder/sources.txt`:

```
COMPANY_NAME=Your Company Name
RIGHTS_STATEMENT=All Rights Reserved
SPECIAL_AUTHOR_user@example.com=User Name https://website.com
FILE_EXT_xyz=# (for custom file extensions)
EXCLUDE_DIR=node_modules
EXCLUDE_DIR=vendor
```

## Usage

The action runs automatically on pull requests. No manual intervention needed.

### Workflow Permissions

The workflow requires:
- `contents: write` - To commit changes back to the PR
- `pull-requests: write` - To comment on the PR

### GitHub Token

Uses the default `GITHUB_TOKEN` provided by GitHub Actions.

## How Copyright Headers are Generated

1. **Author Detection**: Uses `git log` to find the original author of each file
2. **Timestamp**: Uses the file's creation date from git history
3. **Format**: `Copyright [Company], [Year]. [Rights]. Created by [Author] on [Date]`
4. **Updates**: If a header exists, it adds an "Edited by" line instead

## Customization

To customize the copyright format:
1. Edit `CopyrightAdder/sources.txt`
2. Update `COMPANY_NAME` and `RIGHTS_STATEMENT`
3. Add special author mappings as needed
4. Configure excluded directories and custom file extensions