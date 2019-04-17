#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null && pwd)"

if [[ $# -lt 2 ]]
then
    echo "Usage: $0 <compiler> <...args...>"
    exit -1
fi

if [ -z ${ANDROID_BIN_DIR+x} ]
then
    echo "Error: environment variable ANDROID_BIN_DIR must be set"
    exit -1
fi

COMPILER="$1"

exec ccache "$ANDROID_BIN_DIR/$COMPILER" "$@"
