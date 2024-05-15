#!/bin/bash

# Get all namespaces
NAMESPACES=$(microk8s kubectl get namespaces -o custom-columns=":metadata.name" --no-headers)

# Loop through each namespace
for NAMESPACE in $NAMESPACES; do
    # Get pod names in CrashLoopBackOff or error state for the current namespace
    PROBLEMATIC_PODS=$(microk8s kubectl get pods --namespace=$NAMESPACE --field-selector=status.phase!=Running -o custom-columns=":metadata.name" --no-headers)

    # Delete problematic pods in the current namespace
    for POD in $PROBLEMATIC_PODS; do
        microk8s kubectl delete pod $POD --namespace=$NAMESPACE
    done
done

# Delete all pods from all namespaces that start with "ntua-"
microk8s kubectl get pods --all-namespaces --no-headers | awk '/ntua-/{print $1 " " $2}' | xargs -n 2 microk8s kubectl delete pod -n