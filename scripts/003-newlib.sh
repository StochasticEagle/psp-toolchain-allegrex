#!/bin/bash
# newlib by pspdev developers

## Exit with code 1 when any command executed returns a non-zero exit code.
onerr()
{
  exit 1;
}
trap onerr ERR

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE="${ROOT}/components/newlib"
BUILD="${ROOT}/build/newlib"

if [ ! -f "${SOURCE}/configure" ]; then
    echo "ERROR: newlib submodule is not initialized."
    echo "Run: git submodule update --init --recursive --depth=1"
    exit 1
fi

TARGET="psp"
TARG_XTRA_OPTS="${TARG_XTRA_OPTS:-}"

## Determine the maximum number of processes that Make can work with.
PROC_NR=$(getconf _NPROCESSORS_ONLN)

## Create and enter the toolchain/build directory
mkdir -p "${BUILD}"
cd "${BUILD}"

## Configure the build.
if [ ! -f "${BUILD}/Makefile" ]; then
    "${SOURCE}/configure" \
    --prefix="$PSPDEV" \
    --target="$TARGET" \
    --with-sysroot="$PSPDEV/$TARGET" \
    --enable-newlib-retargetable-locking \
    --enable-newlib-multithread \
    --enable-newlib-io-c99-formats \
    --enable-newlib-iconv \
    --enable-newlib-iconv-encodings=us_ascii,utf8,utf16,utf_16be,utf_16le,ucs_2,ucs_2be,ucs_2le,ucs_2_internal,ucs_4_internal,iso_8859_1 \
    $TARG_XTRA_OPTS
fi

## Compile and install.
make --quiet -j "$PROC_NR" all
make --quiet -j "$PROC_NR" install-strip

## Copy license file.
mkdir -p "${PSPDEV}/psp/share/licenses/newlib"
cp "${SOURCE}/COPYING.NEWLIB" "${PSPDEV}/psp/share/licenses/newlib/"

## Store build information.
BUILD_FILE="${PSPDEV}/build.txt"
if [[ -f "${BUILD_FILE}" ]]; then
    sed -i'' '/^newlib /d' "${BUILD_FILE}"
fi

git -C "${SOURCE}" log -1 --format="newlib %H %cs %s" >> "${BUILD_FILE}"
