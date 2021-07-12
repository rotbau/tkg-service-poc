#!/bin/bash

kubectl create secret generic regcred --from-file=.dockerconfigjson=config.json --type=kubernetes.io/dockerconfigjson -n $1
kubectl patch sa default -p '{"imagePullSecrets": [{"name": "regcred"}]}' -n $1
