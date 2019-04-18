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
        if [[ -f out/ios/src/out/${arch}/${build}/libwebrtc_full.a ]]
        then
            echo "Copying out/ios/src/out/${arch}/${build}/libwebrtc_full.a to ${out_dir}/ios/${arch}/${build}/..."
            mkdir -p ${out_dir}/ios/${arch}/${build}
            cp -p out/ios/src/out/${arch}/${build}/libwebrtc_full.a ${out_dir}/ios/${arch}/${build}/
        fi
    done

    # if [[ -f out/mac/src/out/${build}/libwebrtc_full.a ]]
    # then
    #     echo "Copying out/ios/src/out/${build}/libwebrtc_full.a to ${out_dir}/ios/${build}/..."
    #     mkdir -p ${out_dir}/ios/${build}
    #     cp -p out/ios/src/out/${build}/libwebrtc_full.a ${out_dir}/ios/${build}/
    # fi
done
