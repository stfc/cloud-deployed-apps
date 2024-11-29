#!/bin/bash

# Check if the required arguments are provided
if [[ $# -ne 2 ]]; then
    echo "Usage: $0  <environment> <cluster_name>"
    echo "Example: $0 infra dev management"
    exit 1
fi

ENVIRONMENT=$1
CLUSTER_NAME=$2

process_directory() {
    local DIR=$1

    if [[ -d "$DIR" ]]; then
        echo "Processing directory: $DIR"
        cd "$DIR"
        find . -maxdepth 1 -type f -name "*.yaml" -not -name ".sops.yaml" | while read -r SECRET_FILE; do    
            # Update keys based on the .sops.yaml configuration
            sops updatekeys "$SECRET_FILE" -y
            echo "Updated keys for $SECRET_FILE."
        done
    else
        echo "Directory $DIR does not exist. Skipping..."
    fi
}


SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
BASE_DIR="$(dirname "$SCRIPTPATH")"

# Paths to the target directories
CLUSTER_DIR="$BASE_DIR/secrets/$ENVIRONMENT/$CLUSTER_NAME/apps"
SHARED_DIR="$BASE_DIR/secrets/$ENVIRONMENT/_shared/apps"

# if cluster name is management - update all infra secrets too
if [[ "$CLUSTER_NAME" == "management" ]]; then
    for CLUSTER_INFRA_DIR in "$BASE_DIR"/secrets/"$ENVIRONMENT"/*/infra; do
        process_directory "$CLUSTER_INFRA_DIR"
    done
fi

# Process app secrets in the cluster-specific directory
process_directory "$CLUSTER_DIR"

# Process app secrets in the shared directory
process_directory "$SHARED_DIR"
