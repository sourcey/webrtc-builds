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
        if [[ -f out/ios/src/out/${arch}/${build}/libwebrtc_full.a ]]
        then
            echo "Copying out/ios/src/out/${arch}/${build}/libwebrtc_full.a to ${out_dir}/ios/${arch}/${build}/..."
            mkdir -p ${out_dir}/ios/${arch}/${build}
            cp -p out/ios/src/out/${arch}/${build}/libwebrtc_full.a ${out_dir}/ios/${arch}/${build}/
        fi

        if [[ -f out/ios_bitcode/src/out/${arch}/${build}/libwebrtc_full.a ]]
        then
            echo "Copying out/ios_bitcode/src/out/${arch}/${build}/libwebrtc_full.a to ${out_dir}/ios/${arch}/${build}/libwebrtc_full-bitcode.a..."
            mkdir -p ${out_dir}/ios/${arch}/${build}
            cp -p out/ios_bitcode/src/out/${arch}/${build}/libwebrtc_full.a ${out_dir}/ios/${arch}/${build}/libwebrtc_full-bitcode.a
        fi

        if [[ -f out/android/src/out/${arch}/${build}/libwebrtc_full.a ]]
        then
            echo "Copying out/android/src/out/${arch}/${build}/libwebrtc_full.a to ${out_dir}/android/${arch}/${build}/..."
            mkdir -p ${out_dir}/android/${arch}/${build}
            cp -p out/android/src/out/${arch}/${build}/libwebrtc_full.a ${out_dir}/android/${arch}/${build}/
        fi

        for platform in ${platforms[@]}
        do
            if [[ -f out/${platform}/src/out/${arch}/${build}/libwebrtc_full.a ]]
            then
                echo "Copying out/${platform}/src/out/${arch}/${build}/libwebrtc_full.a to ${out_dir}/${platform}/${build}/..."
                mkdir -p ${out_dir}/${platform}/${build}
                cp -p out/${platform}/src/out/${arch}/${build}/libwebrtc_full.a ${out_dir}/${platform}/${build}/
            fi
        done
    done
done
