#!/usr/bin/env bash

# This script extracts environment variables from terraform.tfvars and exports them to the current shell.
#
# Usage: source prep_env.sh
# Arguments: None

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

export PROJECT_ID=$(grep -E '^\s*demo\s*=' "$SCRIPT_DIR/terraform.tfvars" | cut -d'"' -f2)
export PROJECT_ID_EXT=$(grep -E '^\s*external\s*=' "$SCRIPT_DIR/terraform.tfvars" | cut -d'"' -f2)
export REGION=$(grep '^region' "$SCRIPT_DIR/terraform.tfvars" | cut -d'"' -f2)
export TFSTATE_BUCKET=$(grep '^bucket' "$SCRIPT_DIR/terraform.tfvars" | cut -d'"' -f2)
