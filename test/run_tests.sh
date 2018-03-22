#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
WEBRTCBUILDS_FOLDER="$1"
WEBRTCBUILDS_FOLDER=$(cd $WEBRTCBUILDS_FOLDER && pwd -P)
CONFIGS=${2:-Debug Release}

# This is for handling breaking changes between WebRTC versions in our test
WEBRTC_REVISION_NUMBER=$(echo $WEBRTCBUILDS_FOLDER | cut -d- -f2)

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT INT TERM HUP
pushd $tmpdir >/dev/null
  for CONFIG in $CONFIGS; do
    if [[ $(uname) = Linux ]]; then
      export PKG_CONFIG_PATH=$WEBRTCBUILDS_FOLDER/lib/x64/$CONFIG/pkgconfig
      #../out/src/third_party/llvm-build/Release+Asserts/bin/clang++ -v -Wall -pthread -o simple_app $DIR/simple_app.cc \
      #-DWEBRTC_REVISION_NUMBER=$WEBRTC_REVISION_NUMBER \
      #$(pkg-config --cflags --libs --define-variable=WEBRTC_LOCAL=$WEBRTCBUILDS_FOLDER libwebrtc_full) \
      #-lpthread
      c++ -o simple_app $DIR/simple_app.cc \
      -DWEBRTC_REVISION_NUMBER=$WEBRTC_REVISION_NUMBER \
      $(pkg-config --cflags --libs --define-variable=WEBRTC_LOCAL=$WEBRTCBUILDS_FOLDER libwebrtc_full) \
      -lpthread 
    elif [[ $(uname) = Darwin ]]; then
      clang++ -o simple_app $DIR/simple_app.cc -DWEBRTC_POSIX -DWEBRTC_MAC \
        -DWEBRTC_REVISION_NUMBER=$WEBRTC_REVISION_NUMBER \
        -I$WEBRTCBUILDS_FOLDER/include -std=c++11 -stdlib=libc++ \
        $WEBRTCBUILDS_FOLDER/lib/$CONFIG/x64/libwebrtc_full.a \
        -framework Cocoa -framework Foundation -framework IOKit \
        -framework Security -framework SystemConfiguration \
        -framework ApplicationServices -framework CoreServices \
        -framework CoreVideo -framework CoreAudio -framework AudioToolbox \
        -framework QTKit -framework AVFoundation -framework CoreMedia
    else
      echo No test currently exists for this platform
      exit 1
    fi
    ./simple_app
  done
popd >/dev/null
