#!/bin/bash
# pthread-embedded by pspdev developers

## Exit with code 1 when any command executed returns a non-zero exit code.
onerr()
{
  exit 1;
}
trap onerr ERR

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE="${ROOT}/components/pthread"

if [ ! -f "${SOURCE}/platform/psp/Makefile" ]; then
    echo "ERROR: pthread submodule is not initialized."
    echo "Run: git submodule update --init --recursive --depth=1"
    exit 1
fi

## Determine the maximum number of processes that Make can work with.
PROC_NR=$(getconf _NPROCESSORS_ONLN)

cd "${SOURCE}/platform/psp"

## Compile and install.
make --quiet -j "$PROC_NR" all
make --quiet -j "$PROC_NR" install

## Copy license files.
mkdir -p "${PSPDEV}/psp/share/licenses/pthread-embedded"
cp "${SOURCE}"/COPYING.* \
   "${SOURCE}/README.md" \
   "${PSPDEV}/psp/share/licenses/pthread-embedded/"

## Store build information.
BUILD_FILE="${PSPDEV}/build.txt"
if [[ -f "${BUILD_FILE}" ]]; then
  sed -i'' '/^pthread-embedded /d' "${BUILD_FILE}"
fi

git -C "${SOURCE}" log -1 --format="pthread-embedded %H %cs %s" >> "${BUILD_FILE}"
