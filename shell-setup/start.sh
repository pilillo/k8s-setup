#!/usr/bin/env bash

# to do: read these vars from a yaml file, or make it more easily configurable
export CLUSTER_USER="vagrant"
export MASTER_HOST="192.168.50.10"
export MASTER_PORT="6443"
export WORKERS="192.168.50.11 192.168.50.12"
export SSH_KEY_PATH="$HOME/Documents/k8s-setup/nodes/key"
export CIDR_NET="192.168.0.0/16"
export KUBE_VERSION="1.14.1"

./setup.sh
