#!/usr/bin/env bash
set -e

USERNAME="${USERNAME:-"${_REMOTE_USER}"}"

install -m 0755 k3s-tools.sh /usr/local/bin/k3s-tools
install -m 0755 k3d-cilium.sh /usr/local/bin/k3d-cilium

mkdir -p /etc/k3d

cp k3d-dev.yaml /etc/k3d/k3d-dev.yaml
cp k3d-cilium.yaml /etc/k3d/k3d-cilium.yaml



