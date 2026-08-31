#!/bin/bash

show_help()
{
    echo "Use '-b' or '--brew' to install packages with Homebrew,"
    echo "or '-p' or '--port' to install with MacPorts."
    echo "If unspecified, Homebrew is preferred, then MacPorts."
    exit 1
}

if (( $# > 1 )); then
    echo "Invalid number of command line options."
    show_help
fi

PACKAGE_MANAGER=""

if (( $# == 1 )); then
    case "$1" in
        -b|--brew)
            PACKAGE_MANAGER="brew"
            ;;
        -p|--port)
            PACKAGE_MANAGER="port"
            ;;
        *)
            show_help
            ;;
    esac
else
    if command -v brew >/dev/null 2>&1; then
        PACKAGE_MANAGER="brew"
    elif command -v port >/dev/null 2>&1; then
        PACKAGE_MANAGER="port"
    else
        echo "ERROR: Neither Homebrew nor MacPorts is installed."
        exit 1
    fi
fi

case "${PACKAGE_MANAGER}" in
    brew)
        if ! command -v brew >/dev/null 2>&1; then
            echo "ERROR: Homebrew is not installed."
            exit 1
        fi

        brew install \
            gettext \
            texinfo \
            bison \
            flex \
            gnu-sed \
            gsl \
            gmp \
            mpfr \
            libmpc \
            zlib
        ;;

    port)
        if ! command -v port >/dev/null 2>&1; then
            echo "ERROR: MacPorts is not installed."
            exit 1
        fi

        sudo port install \
            gettext \
            texinfo \
            bison \
            flex \
            gsed \
            gsl \
            gmp \
            mpfr \
            libmpc \
            zlib
        ;;
esac
