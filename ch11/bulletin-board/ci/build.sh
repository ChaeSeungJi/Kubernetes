#!/bin/sh

buildctl --addr tcp://buildkitd:1234 \
  build \
  --frontend=gateway.v0 \
  --opt source=kiamol/buildkit-buildpacks \
  --local context=src \
  --output type=image,name=docker.io/twkji/bulletin-board,push=true
