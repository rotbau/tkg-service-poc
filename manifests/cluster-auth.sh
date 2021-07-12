#!/bin/bash
kubectl vsphere login --server=https://10.0.103.20 --insecure-skip-tls-verify -u administrator@vsphere.local --tanzu-kubernetes-cluster-namespace $1 --tanzu-kubernetes-cluster-name $2