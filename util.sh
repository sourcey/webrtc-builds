# Detect host platform.
# Set PLATFORM environment variable to override default behavior.
# Supported platform types - 'linux', 'win', 'mac'
# 'msys' is the git bash shell, built using mingw-w64, running under Microsoft
# Windows.
function detect-platform() {
  # set PLATFORM to android on linux host to build android
  case "$OSTYPE" in
  darwin*)      PLATFORM=${PLATFORM:-mac} ;;
  linux*)       PLATFORM=${PLATFORM:-linux} ;;
  win32*|msys*) PLATFORM=${PLATFORM:-win} ;;
  *)            echo "Building on unsupported OS: $OSTYPE"; exit 1; ;;
  esac
}

# This cleans the output directory.
# $1: The output directory.
function clean() {
  local outdir="$1"
  rm -rf $outdir/* $outdir/.gclient*
}

# Makes sure depot tools are present.
# $1: The platform type.
# $2: The depot tools url.
# $3: The depot tools directory.
function check::depot-tools() {
  local platform="$1"
  local depot_tools_url="$2"
  local depot_tools_dir="$3"

  if [ ! -d $depot_tools_dir ]; then
    git clone -q $depot_tools_url $depot_tools_dir
    if [ $platform = 'win' ]; then
      # run gclient.bat to get python
      pushd $depot_tools_dir >/dev/null
      ./gclient.bat
      popd >/dev/null
    fi
  else
    pushd $depot_tools_dir >/dev/null
      git reset --hard -q
    popd >/dev/null
  fi
}

# Makes sure package is installed. Depends on sudo to be installed first.
# $1: The name of the package
# $2: Existence check binary. Defaults to name of the package.
function ensure-package() {
  local name="$1"
  local binary="${2:-$1}"
  if ! which $binary > /dev/null ; then
    sudo apt-get update -qq
    sudo apt-get install -y $name
  fi
}

# Check if any of the arguments is executable (logical OR condition).
# Using plain "type" without any option because has-binary is intended
# to know if there is a program that one can call regardless if it is
# an alias, builtin, function, or a disk file that would be executed.
function has-binary () {
  type "$1" &> /dev/null ;
}

# Setup Visual Studio build environment variables.
function init-msenv() {

  # Rudimentary support for VS2017 in default install location due to
  # lack of VS1S0COMNTOOLS environment variable.
  if [ -d "C:/Program Files (x86)/Microsoft Visual Studio/2017/Community/VC/Auxiliary/Build" ]; then
    vcvars_path="C:/Program Files (x86)/Microsoft Visual Studio/2017/Community/VC/Auxiliary/Build"
  elif [ ! -z "$VS140COMNTOOLS" ]; then
    vcvars_path="${VS140COMNTOOLS}../../VC"
  else
    echo "Building under Microsoft Windows requires Microsoft Visual Studio 2015 Update 3"
    exit 1
  fi

  export DEPOT_TOOLS_WIN_TOOLCHAIN=0

  pushd "$vcvars_path" >/dev/null
    OLDIFS=$IFS
    IFS=$'\n'
    msvars=$(cmd //c "vcvarsall.bat $TARGET_CPU && set")

    for line in $msvars; do
      case $line in
      INCLUDE=*|LIB=*|LIBPATH=*)
        export $line ;;
      PATH=*)
        PATH=$(echo $line | sed \
          -e 's/PATH=//' \
          -e 's/\([a-zA-Z]\):[\\\/]/\/\1\//g' \
          -e 's/\\/\//g' \
          -e 's/;\//:\//g'):$PATH
        export PATH
        ;;
      esac
    done
    IFS=$OLDIFS
  popd >/dev/null
}

# Makes sure all build environment dependencies are present.
# $1: The platform type.
function check::build::deps() {
  local platform="$1"
  local target_cpu="$2"

  # Required programs
  # TODO: check before running platform specific commands
  REQUIRED_PROGS=(
    bash
    sed
    git
    openssl
    find
    grep
    xargs
    pwd
    curl
    rm
    cat
  )
  # strings

  case $platform in
  mac)
    REQUIRED_PROGS=( "${REQUIRED_PROGS[@]}" brew )

    # for GNU version of cp: gcp
    which gcp || brew install coreutils
    ;;
  linux)
    REQUIRED_PROGS=( "${REQUIRED_PROGS[@]}" strings apt-get )

    if ! grep -v \# /etc/apt/sources.list | grep -q multiverse ; then
      echo "*** Warning: The Multiverse repository is probably not enabled ***"
      echo "*** which is required for things like msttcorefonts.           ***"
    fi
    if ! which sudo > /dev/null ; then
      apt-get update -qq
      apt-get install -y sudo
    fi
    ensure-package curl
    ensure-package git
    ensure-package python
    ensure-package lbzip2
    ensure-package lsb-release lsb_release
    ;;
  win)
    init-msenv
    ;;
  esac

  # Check that required programs exist on the system.
  # If they are missing, we abort.
  for f in "${REQUIRED_PROGS[@]}" ; do
    if ! has-binary "$f" ; then
      echo "Error: '$f' is not installed." >&2
      exit 1
    fi
  done
}

# Makes sure all WebRTC build dependencies are present.
# $1: The platform type.
function check::webrtc::deps() {
  local platform="$1"
  local outdir="$2"
  local target_os="$3"

  case $platform in
  linux)
    # Automatically accepts ttf-mscorefonts EULA
    echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | sudo debconf-set-selections
    sudo $outdir/src/build/install-build-deps.sh --no-syms --no-arm --no-chromeos-fonts --no-nacl --no-prompt
    ;;
  esac

  if [ $target_os = 'android' ]; then
    sudo $outdir/src/build/install-build-deps-android.sh
  fi
}

# Checks out a specific revision
# $1: The target OS type.
# $2: The output directory.
# $3: Revision represented as a git SHA.
function checkout() {
  local target_os="$1"
  local outdir="$2"
  local revision="$3"

  pushd $outdir >/dev/null
  local prev_target_os=$(cat $outdir/.webrtcbuilds_target_os 2>/dev/null)
  if [[ -n "$prev_target_os" && "$target_os" != "$prev_target_os" ]]; then
    echo The target OS has changed. Refetching sources for the new target OS
    rm -rf src .gclient*
  fi

  # Fetch only the first-time, otherwise sync.
  if [ ! -d src ]; then
    case $target_os in
    android)
      yes | fetch --nohooks webrtc_android
      ;;
    ios)
      fetch --nohooks webrtc_ios
      ;;
    *)
      fetch --nohooks webrtc
      ;;
    esac
  fi

  # Remove all unstaged files that can break gclient sync
  # NOTE: need to redownload resources
  pushd src >/dev/null
  # git reset --hard &&
  git clean -f
  popd >/dev/null

  # Checkout the specific revision after fetch
  gclient sync --force --revision $revision

  # Cache the target OS
  echo $target_os > $outdir/.webrtcbuilds_target_os
  popd >/dev/null
}

# Patches a checkout for building static standalone libs
# $1: The platform type.
# $2: The output directory.
function patch() {
  local platform="$1"
  local outdir="$2"
  #local enable_rtti="$3"

  pushd $outdir/src >/dev/null
    # This removes the examples from being built.
    sed -i.bak 's|"//webrtc/examples",|#"//webrtc/examples",|' BUILD.gn

    # This patches a GN error with the video_loopback executable depending on a
    # test but since we disable building tests GN detects a dependency error.
    # Replacing the outer conditional with 'rtc_include_tests' works around this.
    # sed -i.bak 's|if (!build_with_chromium)|if (rtc_include_tests)|' webrtc/BUILD.gn

    # Enable RTTI if required by removing the 'no_rtti' compiler flag.
    # This fixes issues when compiling WebRTC with other libraries that have RTTI enabled.
    # if [ $enable_rtti = 1 ]; then
    #   echo "Enabling RTTI"
    #   sed -i.bak 's|"//build/config/compiler:no_rtti",|#"//build/config/compiler:no_rtti",|' \
    #     build/config/BUILDCONFIG.gn
    # fi
  popd >/dev/null
}

# This function compiles a single library for linux.
#
# $1 The output directory, 'out/$TARGET_CPU/Debug', or 'out/$TARGET_CPU/Release'
# $2 Additional gn arguments
function compile-ninja() {
  local outputdir="$1"
  local gn_args="$2"

  echo "Generating project files with: $gn_args"
  gn gen $outputdir --args="$gn_args"
  pushd $outputdir >/dev/null
    ninja -C .
  popd >/dev/null
}

# This function combines build artifact objects into one library named by
# 'outputlib'.
#
# The Microsoft Windows tools use different file extensions than the other tools:
# '.obj' as the object file extension, instead of '.o'
# '.lib' as the static library file extension, instead of '.a'
# '.dll' as the shared library file extension, instead of '.so'
#
# The Microsoft Windows tools have different names than the other tools:
# 'lib' as the librarian, instead of 'ar'. 'lib' must be found through the path
# variable $VS140COMNTOOLS.
#
# $1: The platform
# $2: The list of object file paths to be combined
# $3: The blacklist objects to exclude from the library
# $4: The output library name
function combine() {
  local platform="$1"
  local outputdir="$2"

  # Blacklist objects from:
  # video_capture_external and device_info_external so that the internal video
  # capture module implementations get linked.
  # unittest_main because it has a main function defined.
  local blacklist="unittest|examples|tools|yasm/|protobuf_lite|main.o|video_capture_external.o|device_info_external.o"
  [ ! -z $3 ] && blacklist="$blacklist|$3"

  # local blacklist="unittest_main.obj|video_capture_external.obj|\
  # device_info_external.obj"
  pushd $outputdir >/dev/null

  # local extras=$(find \
  #   obj/third_party/libvpx/libvpx_* -name "*\.o")
  # echo "$extras" | tr ' ' '\n' >>libwebrtc_full1.list
  #
  # cat libwebrtc_full1.list | grep -v -E $blacklist | xargs ar -cru libwebrtc_full1.a # ar -crs $libname.a
  # # cat libwebrtc_full.list | xargs ar -rcT libwebrtc_full.a
  # # local extras=$(find \
  # #   obj/third_party/libvpx/libvpx_* -name "*\.o")
  #   # echo "$extras"
  #   exit

    rm -f libwebrtc_full.*

    # Method 1: Collect all .o* files from .ninja_deps and some missing intrinsics

    # if [ $platform = 'win' ]; then
    #   local extname='obj'
    # else
    #   local extname='o'
    # fi

    # Method 2: Collect all .o* files from output directory
    # local objlist=$(find . -name '*.o' | grep -v -E $blacklist)
    # echo "$objlist" >$libname.list

    # Combine all objects into one static library. Prevent blacklisted objects
    # such as ones containing a main function from being combined.
    case $platform in
    win)

      # Method 3: Merge only the libraries we need
      if [ $platform = 'win' ]; then
        local whitelist="boringssl.dll.lib|protobuf_lite.dll.lib|webrtc\.lib|field_trial_default.lib|metrics_default.lib"
      # else
        # local whitelist="boringssl\.a|protobuf_full\.a|webrtc\.a|field_trial_default.a|metrics_default.a"
      fi
      cat .ninja_log | tr '\t' '\n' | grep -E $whitelist | sort -u >libwebrtc_full.list

      # TODO: Support VS 2017
      "$VS140COMNTOOLS../../VC/bin/lib" /OUT:libwebrtc_full.lib @libwebrtc_full.list
      ;;
    *)
#       ar -M <<EOM
#         CREATE libwebrtc_full.a
#         ADDLIB obj/third_party/boringssl/libboringssl.a
#         ADDLIB obj/third_party/protobuf/libprotobuf_full.a
#         ADDLIB obj/webrtc/system_wrappers/libfield_trial_default.a
#         ADDLIB obj/webrtc/system_wrappers/libmetrics_default.a
#         ADDLIB obj/webrtc/libwebrtc.a
#         SAVE
#         END
# EOM
#       ranlib libwebrtc_full.a

      # local objlist=$(strings .ninja_deps | grep -o ".*\.o")
      # local extras=$(find \
      #   obj/third_party/libvpx/libvpx_* \
      #   obj/third_party/libjpeg_turbo/simd_asm \
      #   obj/third_party/boringssl/boringssl_asm -name "*\.o")ll
      # echo "$objlist" | tr ' ' '\n' | grep -v -E $blacklist >libwebrtc_full.list
      # echo "$extras" | tr ' ' '\n' >>libwebrtc_full.list
      #
      # cat libwebrtc_full.list | grep -v -E $blacklist | xargs ar -rcs libwebrtc_full.a # ar -crs $libname.a
      # # cat libwebrtc_full.list | xargs ar -rcT libwebrtc_full.a
      # exit


      # Method 2: Collect all .o* files from output directory
      local objlist=$(find obj -name '*.o') #$(find . -name '*.o' | grep -v -E $blacklist)
      echo "$objlist" >libwebrtc_full.list
      cat libwebrtc_full.list | xargs ar -rcT libwebrtc_full.a
      exit
      ;;
    esac
  popd >/dev/null
}

# This compiles the library.
# $1: The platform type.
# $2: The output directory.
function compile() {
  local platform="$1"
  local outdir="$2"
  local target_os="$3"
  local target_cpu="$4"
  local blacklist="$5"

  # local common_args="" FIXME
  # local target_args=""
  # A note on default common args:
  # `rtc_include_tests=false`: Disable all unit tests
  # `is_component_build=true`: Build with dynamic CRT
  # `enable_iterator_debugging=false`: Disable libstdc++ debugging facilities
  # unless all your compiled applications and dependencies define _GLIBCXX_DEBUG=1.
  local common_args="rtc_include_tests=false use_rtti=true" # is_component_build=true
  local target_args="target_os=\"$target_os\" target_cpu=\"$target_cpu\""
  [ $ENABLE_RTTI = 1 ] && target_args+=" use_rtti=true"

  # Comment this out to use clang.
  # `is_clang=false` and `sysroot=false` to build using gcc.
  # NOTE: This was creating corrupted binaries with
  # revision 92ea601e90c3fc12624ce35bb62ceaca8bc07f1b
  target_args+=" is_clang=false"
  [ $platform = 'linux' ] && target_args+=" use_sysroot=false"

  pushd $outdir/src >/dev/null
    compile-ninja "out/$TARGET_CPU/Debug" "$common_args $target_args is_debug=true"
    # compile-ninja "out/$TARGET_CPU/Release" "$common_args $target_args is_debug=false symbol_level=0 enable_nacl=false"

    # Combine output libraries on platforms that support it.
    # Windows is disabled because `lib.exe` does not like linking with the
    # yasm compiled .o objects.
    # if [ ! $platform = 'win' ]; then
      combine $platform "out/$TARGET_CPU/Debug" "$blacklist"
      # combine $platform "out/$TARGET_CPU/Release" "$blacklist"
    # fi
  popd >/dev/null
}

# This packages a compiled build into an archive file in the output directory.
# $1: The platform type.
# $2: The output directory.
# $3: Label of the package.
# $4: The project's resource dirctory.
function package() {
  local platform="$1"
  local outdir="$2"
  local label="$3"
  local resourcedir="$4"

  if [ $platform = 'mac' ]; then
    CP='gcp'
  else
    CP='cp'
  fi

  if [ $platform = 'win' ]; then
    OUTFILE=$label.7z
  else
    OUTFILE=$label.tar.gz
  fi

  pushd $outdir >/dev/null

    # Create directory structure
    mkdir -p $label/include $label/lib/$TARGET_CPU packages
    pushd src >/dev/null

      # Find and copy header files
      find webrtc -name *.h -exec $CP --parents '{}' $outdir/$label/include ';'

      # Find and copy dependencies
      # The following build dependencies were excluded: gflags, ffmpeg, openh264, openmax_dl, winsdk_samples, yasm
      find third_party -name *.h -o -name README -o -name LICENSE -o -name COPYING | \
        grep -E 'boringssl|expat/files|jsoncpp/source/json|libjpeg|libjpeg_turbo|libsrtp|libvpx|opus|protobuf|usrsctp/usrsctpout/usrsctpout' | \
        grep -v /third_party | \
        xargs -I '{}' $CP --parents '{}' $outdir/$label/include
    popd >/dev/null

    # Find and copy libraries
    pushd src/out/$TARGET_CPU >/dev/null
      # find . -name *.so -o -name *.dll -o -name *.lib -o -name *.jar | \
      #   grep -E 'webrtc_full|/webrtc\.|boringssl.dll|protobuf_lite|system_wrappers' | \
      #   xargs -I '{}' $CP --parents '{}' $outdir/$label/lib/$TARGET_CPU

      find . -maxdepth 2 \( -name *.so -o -name *.dll -o -name *webrtc_full* -o -name *.jar \) \
        -exec $CP --parents '{}' $outdir/$label/lib/$TARGET_CPU ';'
    popd >/dev/null

    # For linux, add pkgconfig files
    if [ $platform = 'linux' ]; then
      configs="Debug Release"
      for cfg in $configs; do
        mkdir -p $label/lib/$TARGET_CPU/$cfg/pkgconfig
        CONFIG=$cfg envsubst '$CONFIG' < $resourcedir/pkgconfig/libwebrtc_full.pc.in > \
          $label/lib/$TARGET_CPU/$cfg/pkgconfig/libwebrtc_full.pc
      done
    fi

    # Archive up the package
    rm -f $OUTFILE
    pushd $label >/dev/null
      if [ $platform = 'win' ]; then
        $DEPOT_TOOLS_DIR/win_toolchain/7z/7z.exe a -t7z -m0=lzma2 -mx=9 -mfb=64 -md=32m -ms=on -ir!lib/$TARGET_CPU -ir!linclude -r ../packages/$OUTFILE
      else
        tar -czvf ../packages/$OUTFILE lib/$TARGET_CPU include
      fi
    popd >/dev/null

  popd >/dev/null
}

# This builds and merges the output manifest.
# $1: The platform type.
# $2: The output directory.
# $3: Label of the package.
function manifest() {
  local platform="$1"
  local outdir="$2"
  local label="$3"

  if [ $platform = 'win' ]; then
    OUTFILE=$label.7z
  else
    OUTFILE=$label.tar.gz
  fi

  mkdir -p $outdir/packages
  pushd $outdir/packages >/dev/null
    # Create a JSON manifest
    rm -f $label.json
    cat << EOF > $label.json
{
  "file": "$OUTFILE",
  "date": "$(current-rev-date)",
  "branch": "${BRANCH}",
  "revision": "${REVISION_NUMBER}",
  "sha": "${REVISION}",
  "crc": "$(file-crc $OUTFILE)",
  "target_os": "${TARGET_OS}",
  "target_cpu": "${TARGET_CPU}"
}
EOF

    # # Merge JSON manifests
    # # node manifest.js
    # rm -f manifest.json
    # echo '[' > manifest.json
    # files=(*.json)
    # (
    #   set -- "${files[@]}"
    #   until (( $# == 1 )); do
    #     if [ ! $1 = 'manifest.json' ]; then
    #       cat $1 >> manifest.json
    #       echo ',' >> manifest.json
    #     fi
    #     shift
    #   done
    #   cat $1 >> manifest.json
    # )
    # sed -i ':a;N;$!ba;s/\n//g' manifest.json
    # sed -i 's/{/\n  {/g' manifest.json
    # echo ']' >> manifest.json

  popd >/dev/null
}

# This returns the latest revision date from the current git repo.
function current-rev-date() {
  git log -1 --format=%cd
}

# This returns the latest revision from the git repo.
# $1: The git repo URL
function file-crc() {
  local file_path="$1"
   md5sum $file_path | grep -o '^\S*'
}

# This returns the latest revision from the git repo.
# $1: The git repo URL
function latest-rev() {
  local repo_url="$1"
  git ls-remote $repo_url HEAD | cut -f1
}

# This returns the associated revision number for a given git sha revision
# $1: The git repo URL
# $2: The revision git sha string
function revision-number() {
  local repo_url="$1"
  local revision="$2"
  # This says curl the revision log with text format, base64 decode it using
  # openssl since its more portable than just 'base64', take the last line which
  # contains the commit revision number and output only the matching {#nnn} part
  openssl base64 -d -A <<< $(curl --silent $repo_url/+/$revision?format=TEXT) \
    | tail -1 | egrep -o '{#([0-9]+)}' | tr -d '{}#'
}

# This returns a short revision sha.
# $1: The revision string
function short-rev() {
  local revision="$1"
  echo $revision | cut -c -7
}
