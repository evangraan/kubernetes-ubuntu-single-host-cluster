#!/bin/bash
echo "Install calico"
curl https://docs.projectcalico.org/manifests/calico.yaml -O
kubectl apply -f calico.yaml
