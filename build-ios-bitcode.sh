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

#ios_archs=(\
#    arm64\
#    arm\
#    x86\
#    x64\
#)

ios_archs=(\
    arm64\
    arm\
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
    # Only try to build mobile platforms on Mac
    if [[ $host_platform == "mac" ]]
    then
        # Put ccache in front so it uses ccache
        export PATH=`pwd`/ccache:$ORIG_PATH

        ios_bitcode_extra_build_flags=

        for arch in ${ios_archs[@]}
        do
            if [[ -d out/ios-bitcode/src ]]
            then
                ios_bitcode_extra_build_flags=-x
            fi

            ./build.sh -d -i ${signing_key} -a 1 -e 1 -b branch-heads/64 -c ${arch} -t ios ${ios_bitcode_extra_build_flags} -n ${build} -y 1
        done
    fi
done

