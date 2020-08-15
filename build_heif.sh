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
    heif)
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
        config_opts+=(-DCMAKE_BUILD_TYPE=release)
        mkdir _build && cd _build
        test -f "CMakeLists.txt" && echo -e "\nCMakeLists.txt: \n" >>$config_help &&
            cmake ../srcs -L >>$config_help
        exec_echo cmake ../srcs ${config_opts[*]}
        $JUST_TEST && return 0
        cmake --build .
        cp -rd bin $INSTALL_DIR/
        cp -rd lib $INSTALL_DIR/
        return 0
        ;;
    heif_conformance)
        cp conformance_files/C003.heic $INSTALL_DIR/bin/
        cp conformance_files/C012.heic $INSTALL_DIR/bin/
        cp conformance_files/C012.heic $INSTALL_DIR/bin/
        cp conformance_files/C008.heic $INSTALL_DIR/bin/
        cp conformance_files/C032.heic $INSTALL_DIR/bin/
        cp conformance_files/C032.heic $INSTALL_DIR/bin/
        cp conformance_files/C014.heic $INSTALL_DIR/bin/
        cp conformance_files/C034.heic $INSTALL_DIR/bin/
        return 0
        ;;
    esac
    . $PROJ_ROOT/common
}
TAG_LIST=""   # All supported user custom tags(empty is allowed)
CUSTOM_TAG="" # Set default user tag if not specified(Empty is Supported)
proj_init_handler() {
    heif_src="$PROJ_ROOT/tarball/heif-3.6.0.tar.gz"
    heif_conformance_src="$PROJ_ROOT/tarball/heif_conformance-master.zip"
}
# Initialize the project and configure compilation parameters
proj_init
proj_build heif heif_conformance
proj_pack
