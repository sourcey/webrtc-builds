#!/usr/bin/env bash

os=`uname`
host_platform='Unknown'

if [[ $os == "Darwin" ]]
then
	host_platform="osx"
elif [[ $os == "Linux" ]]
then
	host_platform="lin"
elif [[ $os == "Windows" ]] || [[ $os == CYGWIN* ]] || [[ $os == "msys" ]]
then
	host_platform="win"
fi

ios_archs=(\
    arm64\
    armv7\
    x86\
    x64\
)

android_archs=(\
    arm64-v8a\
    armeabi-v7a\
    x86\
    x86_64\
)

# Put ccache in front so it uses ccache
export PATH=`pwd`/ccache:$PATH

# Only try to build mobile platforms on Mac
if [[ $host_platform == "osx" ]]
then
    for arch in ${ios_archs[@]}
    do
        ./build.sh -i 41963FD7D65A2DE291B7DF06CD161F797057A93D -a 1 -e 1 -d -b branch-heads/64 -c ${arch} -t ios -x
    done

    for arch in ${android_archs[@]}
    do
        ./build.sh -a 1 -e 1 -d -b branch-heads/64 -c ${arch} -t android -x
    done
fi

./build.sh -a 1 -e 1 -d -b branch-heads/64 -x
