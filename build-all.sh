#!/usr/bin/env bash

os=`uname`
host_platform='Unknown'

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

# Start within docker
# docker run -v `pwd`:`pwd` -w `pwd` -i -t ubuntu

for build in ${builds[@]}
do
    # Only try to build mobile platforms on Mac
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

            ./build.sh -d -i 41963FD7D65A2DE291B7DF06CD161F797057A93D -a 1 -e 1 -b branch-heads/64 -c ${arch} -t ios ${ios_extra_build_flags} -n ${build}
        done

        ios_bitcode_extra_build_flags=

        for arch in ${ios_archs[@]}
        do
            if [[ -d out/ios-bitcode/src ]]
            then
                ios_bitcode_extra_build_flags=-x
            fi

            ./build.sh -d -i 41963FD7D65A2DE291B7DF06CD161F797057A93D -a 1 -e 1 -b branch-heads/64 -c ${arch} -t ios ${ios_bitcode_extra_build_flags} -n ${build} -y 1
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

            ./build.sh -d -a 1 -e 1 -b branch-heads/64 -c ${arch} -t android ${android_extra_build_flags} -n ${build}
        done
    fi

    # Put ccache in front so it uses ccache
    export PATH=`pwd`/ccache:$ORIG_PATH

    host_extra_build_flags=

    if [[ -d out/$host_platform/src ]]
    then
        host_extra_build_flags=-x
    fi

    ./build.sh -d -a 1 -e 1 -b branch-heads/64 ${host_extra_build_flags} -n ${build}
done
