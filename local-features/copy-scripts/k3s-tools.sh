#!/bin/sh

echo "Please select from the list of actions"


K3D_START="Start the K3D dev cluster"
K3D_STOP="Stop the K3D dev cluster"
ARGOCD_DEPLOY="Deploy Argo CD"

ACTIONS=$(gum choose --cursor-prefix "[ ] " --selected-prefix "[✓] " --limit=1  --select-if-one "$K3D_START" "$K3D_STOP" "$ARGOCD_DEPLOY")

clear; echo "One moment, please. ${ACTIONS}"

if [ "$ACTIONS" = "$K3D_START" ]; then
    echo "Starting K3D cluster"
    k3d cluster create \
		--config /etc/k3d/k3d-dev.yaml
fi

if [ "$ACTIONS" = "$K3D_STOP" ]; then
    echo "Stopping K3D cluster"
    k3d cluster delete dev
fi

if [ "$ACTIONS" = "$ARGOCD_DEPLOY" ]; then
    # Check if the 'argocd' namespace exists
    if ! kubectl get namespace argocd &> /dev/null; then
        # Namespace does not exist, so create it
        kubectl create namespace argocd
        echo "Namespace 'argocd' created."
    else
        # Namespace already exists
        echo "Namespace 'argocd' already exists."
    fi

	kustomize build /workspaces/catalogue/kustomize/argo-cd/overlays/k3d/ \
		| kubectl apply \
		-n argocd -f -

    # Namespace where the secret should be located
    NAMESPACE="argocd"
    # The name of the secret we're waiting for
    SECRET_NAME="argocd-initial-admin-secret"

    # Loop until the secret is found
    while true; do
        # Check if the secret exists in the specified namespace
        if kubectl get secret $SECRET_NAME -n $NAMESPACE &> /dev/null; then
            echo "Secret '$SECRET_NAME' found in namespace '$NAMESPACE'."
            break # Exit the loop if the secret is found
        else
            echo "Waiting for secret '$SECRET_NAME' to be present in namespace '$NAMESPACE'..."
            sleep 5 # Wait for 5 seconds before checking again
        fi
    done

    ARGOCD_PASSWORD=$(kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath='{.data}' | jq -r '.password' | base64 --decode)

    echo "Argo CD Password:"
    echo "$ARGOCD_PASSWORD"
fi


