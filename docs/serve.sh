#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME="vhogemann-jekyll:local"

docker build -t "$IMAGE_NAME" .

docker run --rm \
  --volume "$PWD:/srv/jekyll" \
  --publish 4000:4000 \
  "$IMAGE_NAME"