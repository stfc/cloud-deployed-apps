
# Check if the required arguments are provided
if [[ $# -ne 2 ]]; then
    echo "Usage: $0  <environment> <cluster_name>"
    echo "Example: $0 staging management"
    exit 1
fi

ENVIRONMENT=$1
CLUSTER_NAME=$2

SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
BASE_DIR="$(dirname "$SCRIPTPATH")"


if [[ $CLUSTER_NAME == "management" ]]; then
    PUBLIC_KEY=$(age-keygen /tmp/$ENVIRONMENT-age-management-key.txt | grep "# public key:" | cut -d' ' -f4)
    # Update .sops.yaml files - replace the temporary ArgoCD key
    for file in "$BASE_DIR/clusters/$ENVIRONMENT/$CLUSTER_NAME/secrets/infra/.sops.yaml" "$BASE_DIR/clusters/$ENVIRONMENT/worker/secrets/infra/.sops.yaml"; do
    if [ -f "$file" ]; then
        # Remove existing temporary ArgoCD key and its comment
        sed -i '/# Temporary key for ArgoCD/,/- age1/d' "$file"
        
        # Add the new temporary key after the age: line
        sed -i "/- age:/a\\
            # Temporary key for ArgoCD\\
            - $PUBLIC_KEY" "$file"
    fi
    done
fi

if [[ $CLUSTER_NAME == "worker" ]]; then
    PUBLIC_KEY=$(age-keygen /tmp/$ENVIRONMENT-age-worker-key.txt | grep "# public key:" | cut -d' ' -f4)
    sed -i '/# Temporary key for ArgoCD/,/- age1/d' "$BASE_DIR/clusters/$ENVIRONMENT/$CLUSTER_NAME/secrets/apps/.sops.yaml"
    # Add the new temporary key after the age: line
    sed -i "/- age:/a\\
        # Temporary key for ArgoCD\\
        - $PUBLIC_KEY" "$BASE_DIR/clusters/$ENVIRONMENT/$CLUSTER_NAME/secrets/apps/.sops.yaml"
fi