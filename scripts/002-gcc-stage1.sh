#!/bin/bash
# gcc-stage1 by pspdev developers

## Exit with code 1 when any command executed returns a non-zero exit code.
onerr()
{
  exit 1;
}
trap onerr ERR

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE="${ROOT}/components/gcc"
BUILD="${ROOT}/build/gcc-stage1"

if [ ! -f "${SOURCE}/configure" ]; then
    echo "ERROR: gcc submodule is not initialized."
    echo "Run: git submodule update --init --recursive --depth=1"
    exit 1
fi

TARGET="psp"
TARG_XTRA_OPTS=""

## Determine the maximum number of processes that Make can work with.
PROC_NR=$(getconf _NPROCESSORS_ONLN)

## If using MacOS Apple, set gmp, mpfr and mpc paths using TARG_XTRA_OPTS
## (this is needed for Apple Silicon but we will do it for all MacOS systems)
if [ "$(uname -s)" = "Darwin" ]; then
    ## Check if using brew
    if command -v brew &> /dev/null; then
        TARG_XTRA_OPTS="--with-gmp=$(brew --prefix gmp) --with-mpfr=$(brew --prefix mpfr) --with-mpc=$(brew --prefix libmpc) --with-system-zlib"
    fi

    ## Check if using MacPorts
    if command -v port &> /dev/null; then
        TARG_XTRA_OPTS="--with-gmp=$(port -q prefix gmp) --with-mpfr=$(port -q prefix mpfr) --with-mpc=$(port -q prefix libmpc) --with-system-zlib"
    fi
fi

## Create and enter the stage 1 build directory.
mkdir -p "${BUILD}"
cd "${BUILD}"

## Configure the bootstrap compiler.
if [ ! -f "${BUILD}/Makefile" ]; then
    "${SOURCE}/configure" \
    --quiet \
    --prefix="$PSPDEV" \
    --target="$TARGET" \
    --enable-languages="c" \
    --with-float=hard \
    --with-headers=no \
    --without-newlib \
    --disable-libgcc \
    --disable-shared \
    --disable-threads \
    --disable-libssp \
    --disable-libgomp \
    --disable-libmudflap \
    --disable-libquadmath \
    --disable-nls \
    $TARG_XTRA_OPTS
fi

## Compile and install the bootstrap compiler.
make --quiet -j "$PROC_NR" all-gcc
make --quiet -j "$PROC_NR" install-gcc
