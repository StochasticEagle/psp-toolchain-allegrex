#!/bin/bash
# pthread-embedded by pspdev developers

## Exit with code 1 when any command executed returns a non-zero exit code.
onerr()
{
  exit 1;
}
trap onerr ERR

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
source "${ROOT}/install-permissions.sh"
SOURCE="${ROOT}/components/pthread"
BUILD="${ROOT}/build/pthread"

if [ ! -f "${SOURCE}/CMakeLists.txt" ]; then
    echo "ERROR: pthread submodule is not initialized."
    echo "Run: git submodule update --init --recursive --depth=1"
    exit 1
fi

## Determine the maximum number of processes that CMake can work with.
PROC_NR=$(getconf _NPROCESSORS_ONLN)

## pthread is part of the compiler bootstrap and is built before PSPSDK exists,
## so it cannot use PSPSDK's pspdev.cmake toolchain file here. Reuse the CMake
## tree only while its configure-defining paths and options still match.
pspdev_prepare_build_tree "pthread" "${BUILD}" "${SOURCE}" \
  "schema=1" \
  "source=${SOURCE}" \
  "build=${BUILD}" \
  "prefix=${PSPDEV}" \
  "cmake=-DCMAKE_SYSTEM_NAME=Generic -DCMAKE_C_COMPILER=${PSPDEV}/bin/psp-gcc -DCMAKE_AR=${PSPDEV}/bin/psp-ar -DCMAKE_RANLIB=${PSPDEV}/bin/psp-ranlib -DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=${PSPDEV}/psp -DPSP_PTHREAD_BUILD_TESTS=OFF"

cmake -S "${SOURCE}" -B "${BUILD}" \
  -DCMAKE_SYSTEM_NAME=Generic \
  -DCMAKE_C_COMPILER="${PSPDEV}/bin/psp-gcc" \
  -DCMAKE_AR="${PSPDEV}/bin/psp-ar" \
  -DCMAKE_RANLIB="${PSPDEV}/bin/psp-ranlib" \
  -DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="${PSPDEV}/psp" \
  -DPSP_PTHREAD_BUILD_TESTS=OFF
pspdev_commit_build_tree "${BUILD}"

cmake --build "${BUILD}" --parallel "${PROC_NR}"
pspdev_run_install cmake --install "${BUILD}"

## Copy license files.
pspdev_run_install mkdir -p "${PSPDEV}/psp/share/licenses/pthread-embedded"
pspdev_run_install cp "${SOURCE}"/COPYING.* \
   "${SOURCE}/README.md" \
   "${PSPDEV}/psp/share/licenses/pthread-embedded/"

## Store build information.
pspdev_record_build_info "pthread-embedded" "$(git -C "${SOURCE}" log -1 --format="pthread-embedded %H %cs %s")"
