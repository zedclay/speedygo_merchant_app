#!/usr/bin/env bash
# Disk preflight for the live parity runners. Source it, then call
#   require_free_disk <step-label>
# before every simulator build/run. It returns 0 when the data volume has at
# least PARITY_MIN_FREE_GB free (default 5), otherwise it prints
# DISK_PREFLIGHT_BLOCKED and returns 75 so the caller stops before the step.
# PARITY_DISK_PATH (default /System/Volumes/Data) selects the volume.

PARITY_MIN_FREE_GB="${PARITY_MIN_FREE_GB:-5}"
PARITY_DISK_PATH="${PARITY_DISK_PATH:-/System/Volumes/Data}"

require_free_disk() {
  local step="${1:-run}" free_kb min_kb
  if ! [[ "$PARITY_MIN_FREE_GB" =~ ^[0-9]+$ ]]; then
    echo "DISK_PREFLIGHT_BLOCKED step=$step reason=invalid PARITY_MIN_FREE_GB='$PARITY_MIN_FREE_GB'" >&2
    return 75
  fi
  free_kb=$(df -k "$PARITY_DISK_PATH" 2>/dev/null | awk 'NR==2 {print $4}')
  if ! [[ "$free_kb" =~ ^[0-9]+$ ]]; then
    echo "DISK_PREFLIGHT_BLOCKED step=$step reason=cannot read free space on $PARITY_DISK_PATH" >&2
    return 75
  fi
  min_kb=$((PARITY_MIN_FREE_GB * 1024 * 1024))
  if (( free_kb < min_kb )); then
    echo "DISK_PREFLIGHT_BLOCKED step=$step free_gb=$((free_kb / 1024 / 1024)) min_gb=$PARITY_MIN_FREE_GB at=$(date -u +%FT%TZ)" >&2
    return 75
  fi
  echo "DISK_PREFLIGHT_OK step=$step free_gb=$((free_kb / 1024 / 1024)) min_gb=$PARITY_MIN_FREE_GB"
}
