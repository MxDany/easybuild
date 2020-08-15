#!/bin/bash
set -Ee
set +x
PROJ_ROOT=$(cd $(dirname $0) && pwd)
. $PROJ_ROOT/scripts/utils
# Build Handler, It will be called in function proj_build().
# CUSTOM_TAG:  User Custom Tag
# PLATFORM:    Platform
# DEV_ARCH:    Device/Arch
# MODE_FLAG:   Share Mode
# BUILD_CROSS: true if it is cross-compile
# JUST_TEST:   true if user just run test, use to skip some operation.
proj_build_handler() {
    case "$name" in
    libjsonc)
        case "$BUILD_PREFER" in
        autoconf)
            # Set library generation rules
            case "$MODE_FLAG" in
            static) config_opts+=("--enable-shared=no --enable-static=yes") ;;
            share) config_opts+=("--enable-shared=yes --enable-static=no") ;;
            both) config_opts+=("--enable-shared=yes --enable-static=yes") ;; esac
            $BUILD_CROSS && config_opts+=(--host=$BUILD_HOST)
            config_opts+=(--with-pic)
            config_opts+=(--prefix=$INSTALL_DIR)
            exec_echo ./configure ${config_opts[*]}
            $JUST_TEST && return 0
            make && make install
            return 0
            ;;
        cmake)
            # Set library generation rules
            case "$MODE_FLAG" in
            static) config_opts+=(-DBUILD_SHARED_LIBS=OFF) ;;
            share) ;& # fallthrough(Since bash 4.0)
            both) config_opts+=(-DBUILD_SHARED_LIBS=ON) ;; esac
            $BUILD_CROSS && {
                config_opts+=(-DCMAKE_SYSTEM_NAME=Linux)
                config_opts+=(-DCMAKE_C_COMPILER=$CC)
                config_opts+=(-DCMAKE_CXX_COMPILER=$CXX)
            }
            case "$PLATFORM-$DEV_ARCH" in
            Dev-Dev01 | Dev-Dev03) config_opts+=(-DCMAKE_EXE_LINKER_FLAGS=-lm) ;; esac
            config_opts+=(-DCMAKE_INSTALL_PREFIX=\"$INSTALL_DIR\")
            config_opts+=(-DCMAKE_BUILD_TYPE=release)
            config_opts+=(-DENABLE_RDRAND=ON)
            mkdir build && cd build
            exec_echo cmake ../ ${config_opts[*]}
            $JUST_TEST && return 0
            cmake --build .
            cmake --install . --strip
            return 0
            ;;
        esac
        ;;
    esac
    . $PROJ_ROOT/common
}

TAG_LIST="old new" # All supported user custom tags(empty is allowed)
CUSTOM_TAG="new"   # Set default user tag if not specified(Empty is Supported)
proj_init_handler() {
    case "$CUSTOM_TAG" in
    old)
        libjsonc_src="$PROJ_ROOT/tarball/json-c-json-c-0.13.1-20180305.tar.gz"
        BUILD_PREFER="autoconf"
        ;;
    new)
        libjsonc_src="$PROJ_ROOT/tarball/json-c-json-c-0.14-20200419.tar.gz"
        BUILD_PREFER="cmake"
        ;;
    esac
}
# Initialize the project and configure compilation parameters
proj_init
proj_build libjsonc
