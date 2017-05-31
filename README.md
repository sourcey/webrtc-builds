# WebRTC Automated Builds

[![CircleCI](https://circleci.com/gh/sourcey/webrtcbuilds.svg?style=svg)](https://circleci.com/gh/sourcey/webrtcbuilds)

These cross platform build scripts make it a pinch to build and package WebRTC.
Just run the scripts and sit back while the hard work is done for you.

## Supported platforms

* **OSX**: [Homebrew](http://brew.sh/) recommend. Build for 'mac' and 'ios'.
* **Windows**: Visual Studio Community 2015 Update 3 or newer
with a bash shell such as [Git for Windows](https://msysgit.github.io) or [MSYS](http://www.mingw.org/wiki/msys)
installed.
* **Linux**: Debian or Ubuntu flavour with `apt-get` available. Build for 'linux' and 'android'.

## Usage

To build the latest version of WebRTC just type:

```
# Build latest WebRTC for current platform:
./build.sh

# To compile a specific branch with both x64 and x86 libraries you would run:
./build.sh -c x64 -b branch-heads/59
./build.sh -c x86 -b branch-heads/59 -x

# To cross compile both x64 and x86 libraries for iOS you would run (on MacOS):
./build.sh -c x64 -t ios
./build.sh -c x86 -t ios -x
```

Or with options:

```
Usage:
   $0 [OPTIONS]

WebRTC automated build script.

OPTIONS:
   -o OUTDIR      Output directory. Default is 'out'
   -b BRANCH      Latest revision on git branch. Overrides -r. Common branch names are 'branch-heads/nn', where 'nn' is the release number.
   -r REVISION    Git SHA revision. Default is latest revision.
   -t TARGET OS   The target os for cross-compilation. Default is the host OS such as 'linux', 'mac', 'win'. Other values can be 'android', 'ios'.
   -c TARGET CPU  The target cpu for cross-compilation. Default is 'x64'. Other values can be 'x86', 'arm64', 'arm'.
   -l BLACKLIST   List *.o objects to exclude from the static library.
   -e             Compile WebRTC with RTII enabled.
   -f             Build only mode. Skip repo sync and dependency checks, just build, compile and package.
   -d             Debug mode. Print all executed commands.
   -h             Show this message
EOF
```

The output packages will be saved to `{OUTDIR}/webrtcbuilds-<rev>-<sha>-<target-os>-<target-cpu>.<ext>`, where `<rev>` is the revision number of the commit, `<sha>` is the short git SHA
of the commit, and `<target-os>-<target-cpu>` is the OS (linux, mac, win) and CPU (x64, x86) of the target environment.

On Windows `7-Zip` is used for compressing packages, which produces vastly superiour output file size. On mac and linux the output file is `tar.gz`.

## Running tests

Once you have compiled the libraries you can run a quick compile test to ensure build integrity:

```
./test/run_tests.sh out/webrtc-17657-02ba69d-linux-x64
```

## Further reading

The following links point to official WebRTC related documentation:

* [https://webrtc.org/native-code/development/](https://webrtc.org/native-code/development/)
* [https://webrtc.org/native-code/development/prerequisite-sw/](https://webrtc.org/native-code/development/prerequisite-sw/)
* [http://dev.chromium.org/developers/how-tos/install-depot-tools](http://dev.chromium.org/developers/how-tos/install-depot-tools)
* [https://chromium.googlesource.com/chromium/src/+/master/docs/windows_build_instructions.md](https://chromium.googlesource.com/chromium/src/+/master/docs/windows_build_instructions.md)
* [https://chromium.googlesource.com/chromium/src/+/master/tools/gn/docs/quick_start.md](https://chromium.googlesource.com/chromium/src/+/master/tools/gn/docs/quick_start.md)
