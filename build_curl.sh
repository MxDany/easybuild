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
    libcurl)
        case "$BUILD_PREFER" in
        autoconf)
            # only for test
            config_opts+=(--enable-debug)
            config_opts+=(--disable-optimize)
            config_opts+=(--enable-curldebug)
            config_opts+=(--enable-verbose)
            
            # Set library generation rules
            case "$MODE_FLAG" in
            static) config_opts+=("--enable-shared=no --enable-static=yes") ;;
            share) config_opts+=("--enable-shared=yes --enable-static=no") ;;
            both) config_opts+=("--enable-shared=yes --enable-static=yes") ;; esac
            config_opts+=(--with-pic)
            config_opts+=(--prefix=$INSTALL_DIR)
            config_opts+=(--with-ssl=$INSTALL_DIR)
            config_opts+=(--with-zlib=$INSTALL_DIR)
            $BUILD_CROSS && config_opts+=(--host=$BUILD_HOST)
            case "$CUSTOM_TAG" in
            svn | svn1) config_opts+=("LIBS=\"-ldl\"") ;;
            esac
            # If openssl has libz, should add '-lz'.
            sed -i "s/-lcrypto -ldl -lpthread/-lcrypto -lz -ldl -lpthread/g" configure
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
            config_opts+=(-DCMAKE_INSTALL_PREFIX=\"$INSTALL_DIR\")
            config_opts+=(-DCMAKE_BUILD_TYPE=release)
            config_opts+=(-DCMAKE_USE_OPENSSL=ON)
            config_opts+=(-DCURL_ZLIB=ON)
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
TAG_LIST="svn svn1 new" # All supported user custom tags(empty is allowed)
CUSTOM_TAG="new"        # Set default user tag if not specified(Empty is Supported)
proj_init_handler() {
    libz_src="$PROJ_ROOT/tarball/zlib-1.2.11.tar.xz"
    case "$CUSTOM_TAG" in
    svn)
        openssl_src="$PROJ_ROOT/tarball/openssl-1.0.1l.tar.gz"
        libcurl_src="$PROJ_ROOT/tarball/curl-7.51.0.tar.bz2"
        ;;
    svn1)
        openssl_src="$PROJ_ROOT/tarball/openssl-1.0.2u.tar.gz"
        libcurl_src="$PROJ_ROOT/tarball/curl-7.51.0.tar.bz2"
        ;;
    new)
        openssl_src="$PROJ_ROOT/tarball/openssl-1.1.1g.tar.gz"
        libcurl_src="$PROJ_ROOT/tarball/curl-7.71.1.tar.bz2"
        ;;
    esac
    BUILD_PREFER="autoconf"
}
# Initialize the project and configure compilation parameters
proj_init
# proj_build libz
# proj_build openssl
proj_build libcurl
# proj_pack
