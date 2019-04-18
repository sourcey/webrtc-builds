#!/usr/bin/env bash

./setup_docker_image.sh

./build.sh -d -a 1 -e 1 -b branch-heads/64 -c arm64 -t android -n Debug
