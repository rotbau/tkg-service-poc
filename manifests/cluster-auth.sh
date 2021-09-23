#!/bin/bash
kubectl vsphere login --server=https://10.0.103.20 -u administrator@vsphere.local --insecure-skip-tls-verify --tanzu-kubernetes-cluster-namespace $1 --tanzu-kubernetes-cluster-name $2