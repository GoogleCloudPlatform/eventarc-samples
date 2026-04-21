#!/usr/bin/env bash
set -e

# This script handles deployment and destruction of various components using Terraform.
# 
# Usage: ./deploy.sh <component> [--destroy] [config_files...]
# Components:
#   all      - Deploys/destroys all components in sequence.
#   infra    - Deploys/destroys common infrastructure.
#   external - Deploys/destroys external services.
#   demo     - Deploys/destroys demo services.
# Flags:
#   --destroy - Destroys resources instead of applying them.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

COMPONENT=""
DESTROY=false
CONFIG_FILES=()

while [[ $# -gt 0 ]]; do
	case $1 in
	--destroy)
		DESTROY=true
		shift
		;;
	*)
		if [ -z "$COMPONENT" ]; then
			COMPONENT=$1
		else
			CONFIG_FILES+=("$1")
		fi
		shift
		;;
	esac
done

if [ -z "$COMPONENT" ]; then
	echo "Usage: $0 <component> [--destroy] [config_files...]"
	echo "Components: all, infra, external, demo"
	exit 1
fi

TF_BUCKET=$(grep '^bucket' "$SCRIPT_DIR/terraform.tfvars" | cut -d'"' -f2)

run_infra() {
	echo "----------------------------------------"
	if [ "$DESTROY" = true ]; then
		echo "🔥 Destroying Infrastructure..."
	else
		echo "📦 Deploying Infrastructure..."
	fi
	echo "----------------------------------------"

	cd "$SCRIPT_DIR/infra"
	terraform init -backend-config="bucket=$TF_BUCKET"

	# Default to demo.yaml if no args passed
	if [ ${#CONFIG_FILES[@]} -eq 0 ]; then
		CONFIG_FILES=("demo.yaml")
	fi

	TF_ARRAY="["
	for i in "${!CONFIG_FILES[@]}"; do
		TF_ARRAY+="\"${CONFIG_FILES[$i]}\""
		if [ $i -lt $((${#CONFIG_FILES[@]} - 1)) ]; then
			TF_ARRAY+=","
		fi
	done
	TF_ARRAY+="]"

	if [ "$DESTROY" = true ]; then
		terraform destroy -var-file="$SCRIPT_DIR/terraform.tfvars" -var="config_files=$TF_ARRAY"
	else
		terraform apply -auto-approve -var-file="$SCRIPT_DIR/terraform.tfvars" -var="config_files=$TF_ARRAY"
	fi
}

run_service() {
	local workspace=$1
	local config_file=$2

	echo "----------------------------------------"
	if [ "$DESTROY" = true ]; then
		echo "🔥 Destroying $workspace services..."
	else
		echo "🚀 Applying $workspace services..."
	fi
	echo "----------------------------------------"

	cd "$SCRIPT_DIR"
	terraform init -backend-config="bucket=$TF_BUCKET"

	terraform workspace select -or-create $workspace
	if [ "$DESTROY" = true ]; then
		terraform destroy -var="config_file=$config_file"
	else
		terraform apply -auto-approve -var="config_file=$config_file"
	fi
}

case $COMPONENT in
infra)
	run_infra
	;;
external)
	run_service external config/external.yaml
	;;
demo)
	run_service demo config/demo.yaml
	;;
all)
	if [ ${#CONFIG_FILES[@]} -eq 0 ]; then
		CONFIG_FILES=("external.yaml" "demo.yaml")
	fi
	if [ "$DESTROY" = true ]; then
		echo "========================================"
		echo "🔥 Starting Full Destruction"
		echo "========================================"
		run_service demo config/demo.yaml
		run_service external config/external.yaml
		run_infra
		echo "========================================"
		echo "✅ All destructions completed successfully!"
		echo "========================================"
	else
		echo "========================================"
		echo "🚀 Starting Full Deployment"
		echo "========================================"
		run_infra
		run_service external config/external.yaml
		run_service demo config/demo.yaml
		echo "========================================"
		echo "✅ All deployments completed successfully!"
		echo "========================================"
	fi
	;;
*)
	echo "Unknown component: $COMPONENT"
	exit 1
	;;
esac
