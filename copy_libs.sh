#!/usr/bin/env bash

if [[ $# -ne 2 ]]
then
    echo "Usage: $0 <out-dir>"
    exit -1
fi

out_dir="$1"

build=(\
    Debug
    Release
)

ios_archs=(\
    arm64\
    arm\
    x86\
    x64\
)

android_archs=(\
    arm64\
    arm\
    x86\
    x64\
)

for build in ${builds[@]}
do
    for arch in ${ios_archs[@]}
    do
        if [[ -f out/ios/src/out/${ios_arch}/${build}/libwebrtc_full.a ]]
        then
            mkdir -p ${out_dir}/ios/${ios_arch}/${build}
            cp -p out/ios/src/out/${ios_arch}/${build}/libwebrtc_full.a ${out_dir}/ios/${ios_arch}/${build}/
        fi
    done
done
