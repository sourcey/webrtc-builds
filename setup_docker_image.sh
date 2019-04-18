#!/usr/bin/env bash

pushd webrtc-builds-android
apt-get update

apt-get -y install python\
	less\
	clang\
	gcc\
	git\
	zip\
	unzip\
    vim

