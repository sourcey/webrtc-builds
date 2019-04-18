#!/usr/bin/env bash

docker run -v `pwd`:`pwd` -w `pwd` -i -t ubuntu `pwd`/start_docker_build.sh
