#!/usr/bin/env bash

docker run --privileged -v `pwd`:`pwd` -w `pwd` -i -t ubuntu:16.04 `pwd`/start_docker_build.sh
