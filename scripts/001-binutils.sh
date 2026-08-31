#!/bin/bash
# binutils by pspdev developers

## Exit with code 1 when any command executed returns a non-zero exit code.
onerr()
{
  exit 1;
}
trap onerr ERR

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE="${ROOT}/components/binutils-gdb"
BUILD="${ROOT}/build/binutils"

if [ ! -f "${SOURCE}/configure" ]; then
    echo "ERROR: binutils-gdb submodule is not initialized."
    echo "Run: git submodule update --init --recursive --depth=1"
    exit 1
fi

TARGET="psp"
TARG_XTRA_OPTS=""

## If using MacOS Apple, set gmp and mpfr paths using TARG_XTRA_OPTS 
## (this is needed for Apple Silicon but we will do it for all MacOS systems)
if [ "$(uname -s)" = "Darwin" ]; then
    ## Check if using brew
    if command -v brew &> /dev/null; then
        TARG_XTRA_OPTS="--with-gmp=$(brew --prefix gmp) --with-mpfr=$(brew --prefix mpfr) --with-system-zlib"
    fi
    ## Check if using MacPorts
    if command -v port &> /dev/null; then
        TARG_XTRA_OPTS="--with-gmp=$(port -q prefix gmp) --with-mpfr=$(port -q prefix mpfr) --with-system-zlib"
    fi
fi

## Determine the maximum number of processes that Make can work with.
PROC_NR=$(getconf _NPROCESSORS_ONLN)

## Create and enter the toolchain/build directory
mkdir -p "${BUILD}"
cd "${BUILD}"

## Build GDB without python support by default
## Set the environment variable WITH_PYTHON to auto to change this
WITH_PYTHON="${WITH_PYTHON:-no}"

## Configure the build.
if [ ! -f "${BUILD}/Makefile" ]; then
    "${SOURCE}/configure" \
    --quiet \
    --prefix="$PSPDEV" \
    --target="$TARGET" \
    --with-sysroot="$PSPDEV/$TARGET" \
    --enable-plugins \
    --disable-initfini-array \
    --with-python="$WITH_PYTHON" \
    --disable-werror \
    $TARG_XTRA_OPTS
fi

## Compile and install.
make --quiet -j "$PROC_NR" all
make --quiet -j "$PROC_NR" install-strip

## Store build information
BUILD_FILE="${PSPDEV}/build.txt"
if [[ -f "${BUILD_FILE}" ]]; then
    sed -i'' '/^binutils /d' "${BUILD_FILE}"
fi

git -C "${SOURCE}" log -1 --format="binutils %H %cs %s" >> "${BUILD_FILE}"
