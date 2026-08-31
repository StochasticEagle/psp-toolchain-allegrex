#!/bin/bash

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

export PSPDEV="${ROOT}/pspdev"
export PATH="${PATH}:${PSPDEV}/bin"

exec "${ROOT}/toolchain.sh" "$@"
