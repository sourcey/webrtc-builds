#!/bin/bash

export VPYTHON_BYPASS="manually managed python not supported by chrome operations"  

set -o errexit
set -o nounset
set -o pipefail
set -eu

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $DIR/util.sh

usage ()
{
cat << EOF

Usage:
   $0 [OPTIONS]

WebRTC automated build script.

OPTIONS:
   -o OUTDIR         Output directory. Default is 'out/<TARGET_OS>'
   -b BRANCH         Latest revision on git branch. Overrides -r. Common branch names are 'branch-heads/nn', where 'nn' is the release number.
   -r REVISION       Git SHA revision. Default is latest revision.
   -t TARGET OS      The target os for cross-compilation. Default is the host OS such as 'linux', 'mac', 'win'. Other values can be 'android', 'ios'.
   -c TARGET CPU     The target cpu for cross-compilation. Default is 'x64'. Other values can be 'x86', 'arm64', 'arm'.
   -l BLACKLIST      List *.o objects to exclude from the static library.
   -e ENABLE_RTTI    Compile WebRTC with RTII enabled. Default is '1'.
   -a ENABLE_CLANG   Enable clang build
   -i CODESIGN       Set the code sign identity for iOS provisioning (IOS_CODE_SIGNING_IDENTITY)
   -n CONFIGS        Build configurations, space-separated. Default is 'Debug Release'. Other values can be 'Debug', 'Release'.
   -y ENABLE_BITCODE Enable bitcode (Applies to iOS build only)
   -x                Express build mode. Skip repo sync and dependency checks, just build, compile and package.
   -D                [Linux] Generate a debian package
   -d                Debug mode. Print all executed commands.
   -h                Show this message
EOF
}

while getopts :o:b:r:t:c:l:e:a:i:n:y:xDd OPTION; do
    case $OPTION in
    o) OUTDIR=$OPTARG ;;
    b) BRANCH=$OPTARG ;;
    r) REVISION=$OPTARG ;;
    t) TARGET_OS=$OPTARG ;;
    c) TARGET_CPU=$OPTARG ;;
    l) BLACKLIST=$OPTARG ;;
    a) ENABLE_CLANG=$OPTARG ;;
    e) ENABLE_RTTI=$OPTARG ;;
    i) IOS_CODE_SIGNING_IDENTITY=$OPTARG ;;
    n) CONFIGS=$OPTARG ;;
    y) ENABLE_BITCODE=$OPTARG ;;
    x) BUILD_ONLY=1 ;;
    x) BUILD_ONLY=1 ;;
    D) PACKAGE_AS_DEBIAN=1 ;;
    d) DEBUG=1 ;;
    ?) usage; exit 1 ;;
    esac
done

BRANCH=${BRANCH:-}
BLACKLIST=${BLACKLIST:-}
ENABLE_CLANG=${ENABLE_CLANG:-1}
ENABLE_RTTI=${ENABLE_RTTI:-1}
ENABLE_ITERATOR_DEBUGGING=0
ENABLE_STATIC_LIBS=1
IOS_CODE_SIGNING_IDENTITY=${IOS_CODE_SIGNING_IDENTITY:-}
BUILD_ONLY=${BUILD_ONLY:-0}
DEBUG=${DEBUG:-0}
CONFIGS=${CONFIGS:-Debug Release}
ENABLE_BITCODE=${ENABLE_BITCODE:-0}
COMBINE_LIBRARIES=${COMBINE_LIBRARIES:-1}
PACKAGE_AS_DEBIAN=${PACKAGE_AS_DEBIAN:-0}
PACKAGE_FILENAME_PATTERN=${PACKAGE_FILENAME_PATTERN:-"webrtc-%rn%-%sr%-%to%-%tc%"}
PACKAGE_NAME_PATTERN=${PACKAGE_NAME_PATTERN:-"webrtc"}
PACKAGE_VERSION_PATTERN=${PACKAGE_VERSION_PATTERN:-"%rn%"}
REPO_URL="https://chromium.googlesource.com/external/webrtc"
DEPOT_TOOLS_URL="https://chromium.googlesource.com/chromium/tools/depot_tools.git"
DEPOT_TOOLS_DIR=$DIR/depot_tools
TOOLS_DIR=$DIR/tools
PATH=python276_bin:$PATH

if [[ -z ${DEPOT_TOOLS_DIR+x} ]]
then
    echo "DEPOT_TOOLS_DIR not defined. Exiting..."
	exit -1
fi

if [[ ! -d $DEPOT_TOOLS_DIR ]]
then
    echo "FATAL: $DEPOT_TOOLS_DIR does not exist..."
    exit -1
fi

echo "ENABLE_BITCODE = ${ENABLE_BITCODE}"

[ "$DEBUG" = 1 ] && set -x

detect-platform
TARGET_OS=${TARGET_OS:-$PLATFORM}
TARGET_CPU=${TARGET_CPU:-x64}

if [[ ${ENABLE_BITCODE} -eq 1 ]]
then
    OUTDIR=${OUTDIR:-out/${TARGET_OS}_bitcode}
else
    OUTDIR=${OUTDIR:-out/${TARGET_OS}}
fi

mkdir -p $OUTDIR
OUTDIR=$(cd $OUTDIR && pwd -P)

echo "Output Directory: $OUTDIR"
echo "Host OS: $PLATFORM"
echo "Target OS: $TARGET_OS"
echo "Target CPU: $TARGET_CPU"

python_major_version=$(python --version 2>&1 | awk '{print $2}' | awk -F. '{print $1}')

if [[ $python_major_version != "2" ]]
then
    echo "ERROR: Python 2 needs to be in path. Detected python version: $python_major_version ($(python --version 2>&1))"
    exit -1
fi

echo Checking build environment dependencies
check::build::env $PLATFORM "$TARGET_CPU"

echo Checking depot-tools
check::depot-tools $PLATFORM $DEPOT_TOOLS_URL $DEPOT_TOOLS_DIR
export PATH=$PATH:$DEPOT_TOOLS_DIR

if [[ ! -d $DEPOT_TOOLS_DIR ]]
then
    echo "FATAL: $DEPOT_TOOLS_DIR does not exist..."
    exit -1
fi

if [ ! -z $BRANCH ]; then
    REVISION=$(git ls-remote $REPO_URL --heads $BRANCH | head -1 | awk '{print $1}') || \
        { echo "Cound not get branch revision" && exit 1; }
   echo "Building branch: $BRANCH"
else
    REVISION=${REVISION:-$(latest-rev "$REPO_URL")} || \
        { echo "Could not get latest revision" && exit 1; }
fi
echo "Building revision: $REVISION"
REVISION_NUMBER=$(revision-number "$REPO_URL" "$REVISION") || \
    { echo "Could not get revision number" && exit 1; }
echo "Associated revision number: $REVISION_NUMBER"
if [ $BUILD_ONLY = 0 ]; then
    echo "Checking out WebRTC revision (this will take a while): $REVISION"
    checkout "$TARGET_OS" $OUTDIR $REVISION

    echo Checking WebRTC dependencies
    check::webrtc::deps $PLATFORM $OUTDIR "$TARGET_OS"

    echo Patching WebRTC source
    patch $PLATFORM $OUTDIR $ENABLE_RTTI
fi

echo Compiling WebRTC
compile $PLATFORM $OUTDIR "$TARGET_OS" "$TARGET_CPU" "$CONFIGS" "$BLACKLIST"

# Default PACKAGE_FILENAME is <projectname>-<rev-number>-<short-rev-sha>-<target-os>-<target-cpu>
PACKAGE_FILENAME=$(interpret-pattern "$PACKAGE_FILENAME_PATTERN" "$PLATFORM" "$OUTDIR" "$TARGET_OS" "$TARGET_CPU" "$BRANCH" "$REVISION" "$REVISION_NUMBER")
PACKAGE_NAME=$(interpret-pattern "$PACKAGE_NAME_PATTERN" "$PLATFORM" "$OUTDIR" "$TARGET_OS" "$TARGET_CPU" "$BRANCH" "$REVISION" "$REVISION_NUMBER")
PACKAGE_VERSION=$(interpret-pattern "$PACKAGE_VERSION_PATTERN" "$PLATFORM" "$OUTDIR" "$TARGET_OS" "$TARGET_CPU" "$BRANCH" "$REVISION" "$REVISION_NUMBER")

echo "Packaging WebRTC: $PACKAGE_FILENAME"
package::prepare $PLATFORM $OUTDIR $PACKAGE_FILENAME $DIR/resource "$CONFIGS" $REVISION_NUMBER
if [ "$PACKAGE_AS_DEBIAN" = 1 ]; then
    package::debian $OUTDIR $PACKAGE_FILENAME $PACKAGE_NAME $PACKAGE_VERSION "$(debian-arch $TARGET_CPU)"
else
    package::archive $PLATFORM $OUTDIR $PACKAGE_FILENAME
    package::manifest $PLATFORM $OUTDIR $PACKAGE_FILENAME
fi

echo Build successful
