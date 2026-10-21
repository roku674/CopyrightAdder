# CLAUDE.md (CopyrightAdder)

## What this is
Standalone scripts that add or update copyright headers in source files, attributing each file to its original
git author and first-commit year. Bash, PowerShell, and Windows batch variants. Config lives in `sources.txt`.

## Inputs
- Owner requests. `sources.txt` (KEY=VALUE: `COMPANY_NAME`, `FILE_EXT_n`, `EXCLUDE_DIR_n`, repo list). No env vars are used.
- No `PROJECT_WORK.md` in this repo.

## Process
```bash
./add_copyright_headers.sh      # Linux/Mac, run from inside the target git repo (or multi-repo via sources.txt)
./check-copyright.sh            # report files missing headers
```
PowerShell and `.bat` equivalents exist for both; keep all three variants in behavioral parity.

## Outputs
- Scripts are consumed by other repos (see `copyright-check-template.yml` and `example-usage.yml` for workflow
  templates). Nothing deploys. Work on `develop`.

## Verification
- Run the script against a scratch git repo and confirm headers and author/year are right; no automated tests. Unknown, verify.
- Do NOT run it against real repos while testing (it rewrites files).

## Read only when needed
| Doing X | Read |
|---|---|
| Features, config keys, usage | `README.md` |
| Security policy | `SECURITY.md` |
| Adding the check to a repo's CI | `copyright-check-template.yml`, `example-usage.yml` |

## Landmines
- `sources.txt` replaced the old environment variables; do not reintroduce env var config.
- `.gitignore` ignores a `CopyrightAdder/` dir (tool is vendored, not a submodule in consumers).
- Never use em/en dashes. No AI attribution in commits.
