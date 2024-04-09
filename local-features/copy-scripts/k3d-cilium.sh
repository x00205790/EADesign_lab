#!/bin/sh

# Mount the bpf filesystem in all nodes
kubectl get nodes -o custom-columns=NAME:.metadata.name --no-headers=true | xargs -I {} docker exec {} mount bpffs /sys/fs/bpf -t bpf
# Change the bpf mount point to a shared mount
kubectl get nodes -o custom-columns=NAME:.metadata.name --no-headers=true | xargs -I {} docker exec {} mount --make-shared /sys/fs/bpf
# https://github.com/cilium/cilium/issues/18675#issuecomment-1051186815
kubectl get nodes -o custom-columns=NAME:.metadata.name --no-headers=true | xargs -I {} docker exec {} mount -t cgroup2 none /run/cilium/cgroupv2
kubectl get nodes -o custom-columns=NAME:.metadata.name --no-headers=true | xargs -I {} docker exec {} mount --make-shared /run/cilium/cgroupv2

# Cilium needs the ip of the serverhost
SERVER_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' k3d-cilium-server-0)
yq e -i '.helmCharts[0].valuesInline.k8sServiceHost=env(SERVER_IP)' kustomize/cilium/base/kustomization.yaml

kustomize build \
    --enable-helm \
    build /workspaces/catalogue/kustomize/cilium/base/ \
    | kubectl apply -f-