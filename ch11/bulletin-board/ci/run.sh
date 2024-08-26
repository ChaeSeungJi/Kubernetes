#!/bin/sh

helm upgrade --install \
  --atomic \
  --set registryServer=docker.io,registryUser=twkji \
  --namespace default \
  bulletin-board \
  helm/bulletin-board
