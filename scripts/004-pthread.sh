#!/bin/bash
# pthread-embedded by pspdev developers

## Exit with code 1 when any command executed returns a non-zero exit code.
onerr()
{
  exit 1;
}
trap onerr ERR

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${ROOT}/install-permissions.sh"
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
pspdev_run_install make --quiet -j "$PROC_NR" install

## Copy license files.
pspdev_run_install mkdir -p "${PSPDEV}/psp/share/licenses/pthread-embedded"
pspdev_run_install cp "${SOURCE}"/COPYING.* \
   "${SOURCE}/README.md" \
   "${PSPDEV}/psp/share/licenses/pthread-embedded/"

## Store build information.
pspdev_record_build_info "pthread-embedded" "$(git -C "${SOURCE}" log -1 --format="pthread-embedded %H %cs %s")"
