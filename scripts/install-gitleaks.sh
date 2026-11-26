#!/usr/bin/env bash
# Installs pinned gitleaks into $RUNNER_TEMP and exports GITLEAKS_BIN.
set -euo pipefail

V="${GITLEAKS_VERSION:-8.30.1}"
dir="${RUNNER_TEMP:-$(mktemp -d)}"
base="https://github.com/gitleaks/gitleaks/releases/download/v${V}"
tar="gitleaks_${V}_linux_x64.tar.gz"

cd "$dir"
curl -sSfL -o "$tar" "$base/$tar"
curl -sSfL -o checksums.txt "$base/gitleaks_${V}_checksums.txt"
grep " ${tar}\$" checksums.txt | sha256sum -c -
tar -xzf "$tar" gitleaks
echo "GITLEAKS_BIN=$dir/gitleaks" >> "${GITHUB_ENV:-/dev/null}"
