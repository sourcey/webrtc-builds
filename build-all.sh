#!/usr/bin/env bash

export VPYTHON_BYPASS="manually managed python not supported by chrome operations"  

os=`uname`
host_platform='Unknown'

branch_head='branch-heads/m79'

if [[ $os == "Darwin" ]]
then
	host_platform="mac"
elif [[ $os == "Linux" ]]
then
	host_platform="lin"
elif [[ $os == "Windows" ]] || [[ $os == CYGWIN* ]] || [[ $os == "msys" ]]
then
	host_platform="win"
fi

ios_archs=(\
    arm64\
    arm\
    x86\
    x64\
)

ios_bitcode_archs=(\
    arm64\
    arm\
)

android_archs=(\
    arm64\
    arm\
    x86\
    x64\
)

builds=(\
    Debug\
    Release\
)

ORIG_PATH=$PATH

signing_key=23099743C8BA1794F2740232AEB790196C08A522

# Start within docker
# docker run -v `pwd`:`pwd` -w `pwd` -i -t ubuntu

for build in ${builds[@]}
do
    Only try to build mobile platforms on Mac
    if [[ $host_platform == "mac" ]]
    then
        # Put ccache in front so it uses ccache
        export PATH=`pwd`/ccache:$ORIG_PATH

        ios_extra_build_flags=

        for arch in ${ios_archs[@]}
        do
            if [[ -d out/ios/src ]]
            then
                ios_extra_build_flags=-x
            fi

            ./build.sh -d -i ${signing_key} -a 1 -e 1 -b ${branch_head} -c ${arch} -t ios ${ios_extra_build_flags} -n ${build}
        done

        ios_bitcode_extra_build_flags=

        for arch in ${ios_bitcode_archs[@]}
        do
            if [[ -d out/ios-bitcode/src ]]
            then
                ios_bitcode_extra_build_flags=-x
            fi

            ./build.sh -d -i ${signing_key} -a 1 -e 1 -b ${branch_head} -c ${arch} -t ios ${ios_bitcode_extra_build_flags} -n ${build} -y 1
        done
    fi

    if [[ $host_platform == "lin" ]]
    then
        # No ccache for Android build for now
        export PATH=$ORIG_PATH

        android_extra_build_flags=

        for arch in ${android_archs[@]}
        do
            if [[ -d out/android/src ]]
            then
                android_extra_build_flags=-x
            fi

            ./build.sh -d -a 1 -e 1 -b ${branch_head} -c ${arch} -t android ${android_extra_build_flags} -n ${build}
        done
    fi

    # Put ccache in front so it uses ccache
    export PATH=`pwd`/ccache:$ORIG_PATH

    host_extra_build_flags=

    if [[ -d out/$host_platform/src ]]
    then
        host_extra_build_flags=-x
    fi

    ./build.sh -d -a 1 -e 1 -b ${branch_head} ${host_extra_build_flags} -n ${build}
done
