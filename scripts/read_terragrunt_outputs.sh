#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   read_terragrunt_outputs.sh <terragrunt_module_path>
#
# Example:
#   read_terragrunt_outputs.sh terragrunt/live/website
#
# Outputs:
#   Writes distribution_id and bucket_name to $GITHUB_OUTPUT

MODULE_PATH="${1:-}"

if [[ -z "$MODULE_PATH" ]]; then
  echo "ERROR: Missing module path argument" >&2
  exit 1
fi

cd "$MODULE_PATH"

# Extract JSON outputs
OUT_JSON=$(terragrunt output --json)

# Parse values safely
DISTRIBUTION_ID=$(echo "$OUT_JSON" | jq -r '.distribution_id.value // empty')
BUCKET_NAME=$(echo "$OUT_JSON" | jq -r '.bucket_name.value // empty')

# Validate
if [[ -z "$DISTRIBUTION_ID" ]]; then
  echo "ERROR: distribution_id output is missing or empty" >&2
  exit 1
fi

if [[ -z "$BUCKET_NAME" ]]; then
  echo "ERROR: bucket_name output is missing or empty" >&2
  exit 1
fi

# Export to GitHub Actions if available
if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  echo "distribution_id=$DISTRIBUTION_ID" >> "$GITHUB_OUTPUT"
  echo "bucket_name=$BUCKET_NAME" >> "$GITHUB_OUTPUT"
else
  echo "GITHUB_OUTPUT not set; printing values for local use"
  echo "distribution_id=$DISTRIBUTION_ID"
  echo "bucket_name=$BUCKET_NAME"
fi
