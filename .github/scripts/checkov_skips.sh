#!/usr/bin/env bash
# Print a comma-separated list of every check ID suppressed inline
# (# checkov:skip=ID: reason) in a project's .tf files.
# Plan JSON carries no comments, so the plan scan reuses the same
# justified suppressions as the static scan via --skip-check.
set -euo pipefail
dir="${1:?project directory}"
grep -rhoE 'checkov:skip=[A-Z0-9_]+' --include='*.tf' "$dir" \
  | cut -d= -f2 | sort -u | paste -sd, -
