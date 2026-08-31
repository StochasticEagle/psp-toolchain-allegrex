#!/bin/bash
# toolchain.sh by fjtrujy

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD="${ROOT}/build"

## PSPDEV is the authoritative installation location.
if [[ -z "${PSPDEV:-}" ]]; then
  echo "ERROR: PSPDEV environment variable is not set."
  exit 1
fi
pspdev
## Make sure this toolchain's binaries take precedence during later stages.
export PATH="${PSPDEV}/bin:${PATH}"

## Create and enter the build directory.
mkdir -p "${BUILD}" || {
  echo "ERROR: Could not create the build directory."
  exit 1
}

cd "${BUILD}" || {
  echo "ERROR: Could not enter the build directory."
  exit 1
}

## Collect dependency and build scripts.
shopt -s nullglob
DEPEND_SCRIPTS=("${ROOT}"/depends/*.sh)
BUILD_SCRIPTS=("${ROOT}"/scripts/*.sh)
shopt -u nullglob

## Run dependency checks.
for SCRIPT in "${DEPEND_SCRIPTS[@]}"; do
  "$SCRIPT" || {
    echo "${SCRIPT}: Failed."
    exit 1
  }
done

if (( ${#BUILD_SCRIPTS[@]} == 0 )); then
  echo "ERROR: No build scripts found."
  exit 1
fi

## If specific steps were requested...
if (( $# > 0 )); then

  for STEP in "$@"; do
    if [[ ! "${STEP}" =~ ^[1-9][0-9]*$ ]] ||
       (( STEP > ${#BUILD_SCRIPTS[@]} )); then
      echo "ERROR: Invalid build step '${STEP}'."
      echo "Valid steps are 1-${#BUILD_SCRIPTS[@]}."
      exit 1
    fi

    SCRIPT="${BUILD_SCRIPTS[STEP-1]}"

    "${SCRIPT}" || {
      echo "${SCRIPT}: Failed."
      exit 1
    }
  done

else

  ## Run all build scripts.
  for SCRIPT in "${BUILD_SCRIPTS[@]}"; do
    "${SCRIPT}" || {
      echo "${SCRIPT}: Failed."
      exit 1
    }
  done

fi

## Store build information.
BUILD_FILE="${PSPDEV}/build.txt"

if [[ -f "${BUILD_FILE}" ]]; then
  sed -i'' '/^psp-toolchain-allegrex /d' "${BUILD_FILE}"
fi

git -C "${ROOT}" log -1 --format="psp-toolchain-allegrex %H %cs %s" >> "${BUILD_FILE}"
