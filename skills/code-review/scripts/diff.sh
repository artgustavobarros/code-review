#!/usr/bin/env bash
# Print the filtered review diff (the one every reviewer reads). Run from the repository root.
#
#   diff.sh <base> [--local] [--no-ignore]
#
# Same noise filter as prepass.sh (see lib.sh). With --local, uncommitted changes are appended.
set -uo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$here/lib.sh"

base="${1:?base ref required}"
shift
local_mode=0
for arg in "$@"; do
  case "$arg" in
    --local) local_mode=1 ;;
    --no-ignore) export CODE_REVIEW_NO_IGNORE=1 BUGPOOL_NO_IGNORE=1 ;;
  esac
done
review_diff "$base" "$local_mode"
