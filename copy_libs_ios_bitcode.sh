#!/usr/bin/env bash

if [[ $# -lt 1 ]]
then
    echo "Usage: $0 <out-dir>"
    exit -1
fi

out_dir="$1"

builds=(\
    Debug\
    Release\
)

archs=(\
    arm64\
    arm\
    x86\
    x64\
)

platforms=(
    mac\
    linux\
    win\
)

for build in ${builds[@]}
do
    for arch in ${archs[@]}
    do
        if [[ -f out/ios_bitcode/src/out/${arch}/${build}/libwebrtc_full.a ]]
        then
            echo "Copying out/ios_bitcode/src/out/${arch}/${build}/libwebrtc_full.a to ${out_dir}/ios/${arch}/${build}/libwebrtc_full-bitcode.a..."
            mkdir -p ${out_dir}/ios/${arch}/${build}
            cp -p out/ios_bitcode/src/out/${arch}/${build}/libwebrtc_full.a ${out_dir}/ios/${arch}/${build}/libwebrtc_full-bitcode.a
        fi
    done
done
