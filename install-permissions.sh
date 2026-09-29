#!/usr/bin/env bash
# Shared PSPDEV install-permission helpers.
#
# Build commands run with the current process permissions. Installation
# commands elevate only when the current process cannot write the PSPDEV prefix.

pspdev_prefix_is_writable() {
    local target="${PSPDEV:-}"
    local parent dir next
    [[ -n "${target}" ]] || return 1

    if [[ -e "${target}" ]]; then
        [[ -d "${target}" && -w "${target}" && -x "${target}" ]] || return 1
        while IFS= read -r -d '' dir; do
            [[ -w "${dir}" && -x "${dir}" ]] || return 1
        done < <(find "${target}" -type d -print0)
        return 0
    fi

    parent="${target}"
    while [[ ! -e "${parent}" ]]; do
        next="$(dirname "${parent}")"
        [[ "${next}" != "${parent}" ]] || break
        parent="${next}"
    done

    [[ -d "${parent}" && -w "${parent}" && -x "${parent}" ]]
}

pspdev_prepare_install() {
    if pspdev_prefix_is_writable; then
        PSPDEV_INSTALL_ELEVATED=0
        return 0
    fi

    if ! command -v sudo >/dev/null 2>&1; then
        echo "ERROR: ${PSPDEV:-<unset>} is not writable by the current process and sudo is unavailable." >&2
        return 1
    fi

    PSPDEV_INSTALL_ELEVATED=1
}

pspdev_run_install() {
    if [[ -z "${PSPDEV_INSTALL_ELEVATED+x}" ]]; then
        pspdev_prepare_install || return 1
    fi

    if (( PSPDEV_INSTALL_ELEVATED )); then
        sudo env \
            "PSPDEV=${PSPDEV}" \
            "PATH=${PATH}" \
            "LD_LIBRARY_PATH=${LD_LIBRARY_PATH:-}" \
            "$@"
    else
        "$@"
    fi
}


pspdev_build_tree_has_stale_paths() {
    local build="$1"
    local source="$2"
    local file line path

    [[ -d "${build}" ]] || return 1

    while IFS= read -r -d '' file; do
        while IFS= read -r line; do
            if [[ "${line}" =~ ^(srcdir|top_srcdir|abs_srcdir|abs_top_srcdir)[[:space:]]*=[[:space:]]*(.*)$ ]]; then
                path="${BASH_REMATCH[2]}"
                if [[ "${path}" == "~/"* || ( "${path}" == /* && "${path}" != "${source}" && "${path}" != "${source}/"* ) ]]; then
                    return 0
                fi
            elif [[ "${line}" =~ ^(builddir|top_builddir|abs_builddir|abs_top_builddir)[[:space:]]*=[[:space:]]*(.*)$ ]]; then
                path="${BASH_REMATCH[2]}"
                if [[ "${path}" == "~/"* || ( "${path}" == /* && "${path}" != "${build}" && "${path}" != "${build}/"* ) ]]; then
                    return 0
                fi
            fi
        done < "${file}"
    done < <(find "${build}" -type f -name Makefile -print0)

    return 1
}

pspdev_prepare_build_tree() {
    local stage="$1"
    local build="$2"
    local source="$3"
    shift 3

    local marker="${build}/.pspdev-build-state"
    local pending="${marker}.pending"
    local expected reset_reason=""

    expected="$(printf '%s\n' "$@")"

    if [[ -d "${build}" ]]; then
        if [[ -f "${marker}" ]]; then
            if [[ "$(cat "${marker}")" != "${expected}" ]]; then
                reset_reason="configuration changed"
            fi
        elif pspdev_build_tree_has_stale_paths "${build}" "${source}"; then
            reset_reason="relocated generated paths detected"
        fi
    fi

    if [[ -n "${reset_reason}" ]]; then
        echo "Refreshing ${stage} build tree: ${reset_reason}."
        rm -rf "${build}"
    fi

    mkdir -p "${build}"
    printf '%s\n' "$@" > "${pending}"
}

pspdev_commit_build_tree() {
    local build="$1"
    local marker="${build}/.pspdev-build-state"
    local pending="${marker}.pending"

    [[ -f "${pending}" ]] || {
        echo "ERROR: Missing pending build-state marker: ${pending}" >&2
        return 1
    }

    mv -f "${pending}" "${marker}"
}

pspdev_record_build_info() {
    local key="$1"
    local line="$2"
    local build_file="${PSPDEV}/build.txt"

    pspdev_run_install sh -c '
        file="$1"
        key="$2"
        line="$3"
        tmp="$(mktemp)"
        if [ -f "$file" ]; then
            grep -v "^$key " "$file" > "$tmp" || true
        fi
        printf "%s\n" "$line" >> "$tmp"
        mkdir -p "$(dirname "$file")"
        install -m 644 "$tmp" "$file"
        rm -f "$tmp"
    ' _ "${build_file}" "${key}" "${line}"
}
