#!/usr/bin/env bash

docker run -v `pwd`:`pwd` -w `pwd` -i -t ubuntu start_docker_build.sh
