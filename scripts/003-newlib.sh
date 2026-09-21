#!/bin/bash
# newlib by pspdev developers

## Exit with code 1 when any command executed returns a non-zero exit code.
onerr()
{
  exit 1;
}
trap onerr ERR

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${ROOT}/install-permissions.sh"
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

## Newlib's generated build/install rules depend on the selected sysdir header
## layout. Reconfigure from a clean tree so newly added or moved PSP headers
## cannot be hidden by stale generated makefiles.
rm -rf "${BUILD}"
mkdir -p "${BUILD}"
cd "${BUILD}"

## Configure the build.
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

## Compile and install.
make --quiet -j "$PROC_NR" all
pspdev_run_install make --quiet -j "$PROC_NR" install-strip

## Verify that the PSP sysroot contains the network compatibility surface
## required by PSPSDK and package builds.
for header in \
    "${PSPDEV}/psp/include/netdb.h" \
    "${PSPDEV}/psp/include/arpa/inet.h" \
    "${PSPDEV}/psp/include/netinet/in.h" \
    "${PSPDEV}/psp/include/netinet/tcp.h"; do
    if [ ! -f "${header}" ]; then
        echo "ERROR: newlib did not install required PSP header: ${header}" >&2
        exit 1
    fi
done

grep -q 'struct addrinfo' "${PSPDEV}/psp/include/netdb.h" || {
    echo "ERROR: installed PSP netdb.h lacks struct addrinfo." >&2
    exit 1
}
grep -q 'getaddrinfo' "${PSPDEV}/psp/include/netdb.h" || {
    echo "ERROR: installed PSP netdb.h lacks getaddrinfo()." >&2
    exit 1
}

## Copy license file.
pspdev_run_install mkdir -p "${PSPDEV}/psp/share/licenses/newlib"
pspdev_run_install cp "${SOURCE}/COPYING.NEWLIB" "${PSPDEV}/psp/share/licenses/newlib/"

## Store build information.
pspdev_record_build_info "newlib" "$(git -C "${SOURCE}" log -1 --format="newlib %H %cs %s")"
