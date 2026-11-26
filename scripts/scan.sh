#!/usr/bin/env bash
# Usage: scan.sh <repo-dir> [git-log-range]
# Default gitleaks rules + email rule, plus the scanned repo's own
# .gitleaks.toml and .gitleaksignore. No range scans full history.
set -euo pipefail

src="$(cd "$1" && pwd)"
range="${2:-}"
here="$(cd "$(dirname "$0")/.." && pwd)"
gitleaks="${GITLEAKS_BIN:-gitleaks}"
work="$(mktemp -d)"
cfg="$work/gitleaks.toml"
report="$work/report.json"

# Repo config stays top-level; gitleaks drops targetRules allowlists of extended configs.
{
  if [ -f "$src/.gitleaks.toml" ]; then
    cat "$src/.gitleaks.toml"
    echo
  fi
  if ! grep -qE '^[[:space:]]*\[extend\]' "$src/.gitleaks.toml" 2>/dev/null; then
    printf '[extend]\nuseDefault = true\n\n'
  fi
  cat "$here/rules/email.toml"
} > "$cfg"

args=(git "$src" --config "$cfg" --gitleaks-ignore-path "$src"
  --redact --no-banner --exit-code 0
  --report-format json --report-path "$report")
if [ -n "$range" ]; then
  args+=(--log-opts "--no-merges $range")
fi
if ! (cd "$work" && "$gitleaks" "${args[@]}"); then
  echo "::error::gitleaks failed to run; check the repo's .gitleaks.toml is valid gitleaks v8 config."
  exit 2
fi

count="$(jq length "$report")"
if [ "$count" -eq 0 ]; then
  echo "gitleaks: no leaks found"
  exit 0
fi

jq -r '.[] | "::error file=\(.File),line=\(.StartLine),title=\(.RuleID)::\(.Description). To allow, add to .gitleaksignore: \(.Fingerprint)"' "$report"

if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
  {
    echo "### gitleaks: $count finding(s)"
    echo
    echo "| Rule | File | Line | Commit | Fingerprint |"
    echo "|---|---|---|---|---|"
    jq -r '.[] | "| \(.RuleID) | `\(.File)` | \(.StartLine) | `\(.Commit[0:12])` | `\(.Fingerprint)` |"' "$report"
    echo
    echo "Remove the value, or add its fingerprint to \`.gitleaksignore\`."
    echo "Allow by value: add an \`[[allowlists]]\` entry to the repo's \`.gitleaks.toml\`."
  } >> "$GITHUB_STEP_SUMMARY"
fi
exit 1
