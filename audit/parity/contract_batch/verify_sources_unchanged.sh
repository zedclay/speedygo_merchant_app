#!/usr/bin/env bash
# Verifies that no backend or Merchant source, test, migration or isolated-
# environment script changed since the snapshot taken before the
# documentation-only closeout. Read-only.
#   usage: verify_sources_unchanged.sh <snapshot.sha> (run from the workspace root)
set -euo pipefail
snapshot="${1:?snapshot file required}"

echo "== hashes of snapshotted files"
if shasum -a 256 -c --quiet "$snapshot"; then
  echo "UNCHANGED $(wc -l < "$snapshot" | tr -d ' ') files"
else
  echo "CHANGED (see lines above)"
  exit 1
fi

echo "== files present now but absent from the snapshot"
current=$(mktemp)
{
  find apps/backend/src apps/backend/prisma apps/backend/test apps/backend/migrations \
    apps/merchant_app/lib apps/merchant_app/test apps/merchant_app/integration_test \
    -type f ! -name '.DS_Store' ! -path '*/__pycache__/*'
  find apps/merchant_app/audit/parity/isolated -maxdepth 1 -type f ! -name '.DS_Store'
} | sort > "$current"
awk '{print $2}' "$snapshot" | sort > "$current.snap"
added=$(comm -23 "$current" "$current.snap")
removed=$(comm -13 "$current" "$current.snap")
rm -f "$current" "$current.snap"
if [[ -n "$added" || -n "$removed" ]]; then
  echo "ADDED:"; echo "$added"
  echo "REMOVED:"; echo "$removed"
  exit 1
fi
echo "NONE ADDED, NONE REMOVED"
