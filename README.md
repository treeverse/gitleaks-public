# gitleaks-public

Org-wide gitleaks check for every public treeverse repo: gitleaks' default
secret rules plus an email-address rule. Enforced by an org ruleset, so no
workflow is added to the public repos and new public repos are covered
automatically.

## What a PR sees

The check scans only the commits in the PR (added or changed lines). Existing
content is flagged only when a PR adds or changes that line.

On a finding, either remove the value or allow it in the PR's repo:

- **One occurrence:** add the fingerprint printed by the check to `.gitleaksignore`
  (`commit:file:rule:line`), same as for secrets today.
- **By value or path:** add an allowlist to the repo's `.gitleaks.toml`:

  ```toml
  [extend]
  useDefault = true

  [[allowlists]]
  targetRules = ["email-address"]
  regexes = ['''^support@treeverse\.io$''']
  ```

Each repo keeps its own allowlists; this repo holds rules only. If a repo has a
`.gitleaks.toml`, the check extends it, so its existing rules and allowlists apply.
Allowlisted in the email rule for everyone: `example.com`, GitHub noreply,
`git@...` remotes, `@2x` image names.

## Layout

- `.github/workflows/gitleaks.yml` — the required workflow.
- `.github/workflows/full-scan.yml` — manual full-history report over all public repos.
- `rules/email.toml` — the email rule.
- `scripts/scan.sh` — builds the config and runs gitleaks.

## Org setup

Org ruleset (Settings → Rules → Rulesets → New branch ruleset):

- Target: public repositories, default branch.
- Rule "Require workflows to pass before merging":
  `treeverse/gitleaks-public`, `.github/workflows/gitleaks.yml`, ref `main`.
- Evaluate mode first, then Active.

## Local run

```sh
GITLEAKS_BIN=gitleaks scripts/scan.sh /path/to/repo            # full history
GITLEAKS_BIN=gitleaks scripts/scan.sh /path/to/repo main..HEAD # range
```
