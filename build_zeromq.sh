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
    liblz4)
        $BUILD_CROSS && {
            config_opts+=(CC=$CC)
            config_opts+=(AR=$AR)
            config_opts+=(RANLIB=$RANLIB)
        }
        config_opts+=(PREFIX=$INSTALL_DIR)
        rm -f $INSTALL_DIR/bin/*lz4*
        exec_echo "make install ${config_opts[*]}"
        # Set library generation rules
        case "$MODE_FLAG" in
        static) rm $INSTALL_DIR/lib/liblz4.so* ;;
        share) rm $INSTALL_DIR/lib/liblz4.a ;;
        both) ;; esac
        return 0
        ;;
    libuuid | libsodium | libmicrohttpd)
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
    libzmq)
        case "$CUSTOM_TAG" in
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
            make
            make install
            ;;
        cmake)
            $BUILD_CROSS && {
                config_opts+=(-DCMAKE_SYSTEM_NAME=Linux)
                config_opts+=(-DCMAKE_C_COMPILER=$CC)
                config_opts+=(-DCMAKE_CXX_COMPILER=$CXX)
            }
            # Set library generation rules
            case "$MODE_FLAG" in
            static) config_opts+=("-DBUILD_SHARED=OFF -DBUILD_STATIC=ON") ;;
            share) config_opts+=("-DBUILD_SHARED=ON -DBUILD_STATIC=OFF") ;;
            both) config_opts+=("-DBUILD_SHARED=ON -DBUILD_STATIC=ON") ;; esac
            config_opts+=(-DZMQ_BUILD_TESTS=OFF)
            config_opts+=(-DWITH_LIBSODIUM=ON)
            config_opts+=(-DCMAKE_BUILD_TYPE=release)
            config_opts+=(-DCMAKE_INSTALL_PREFIX=$INSTALL_DIR)
            mkdir build && cd build
            exec_echo cmake ../ ${config_opts[*]}
            $JUST_TEST && return 0
            # cmake --build . --config Release --target install
            make
            make install
            ;;
        esac
        return 0
        ;;
    libczmq)
        case "$CUSTOM_TAG" in
        autoconf)
            # Set library generation rules
            case "$MODE_FLAG" in
            static) config_opts+=("--enable-shared=no --enable-static=yes") ;;
            share) config_opts+=("--enable-shared=yes --enable-static=no") ;;
            both) config_opts+=("--enable-shared=yes --enable-static=yes") ;; esac
            $BUILD_CROSS && config_opts+=(--host=$BUILD_HOST)
            config_opts+=(--with-pic)
            config_opts+=(--prefix=$INSTALL_DIR)
            config_opts+=(--with-libzmq=yes)
            config_opts+=(--enable-drafts=no)
            config_opts+=(--with-docs=no)
            config_opts+=(--with-uuid=yes)
            exec_echo ./configure ${config_opts[*]}
            $JUST_TEST && return 0
            case "$PLATFORM-$DEV_ARCH" in
            Dev-Dev01 | Dev-Dev03 | Dev-Dev04 | Dev-Dev05)
                # 编译失败，只能手动从.lib文件夹中复制缓存文件
                make 2>/dev/null || echo_e "Some errors occur when run 'make', skip it."
                make install 2>/dev/null || echo_e "Some errors occur when run 'make install', skip it."
                # 从缓存目录中复制出动态库和静态库
                mkdir -p $INSTALL_DIR/lib
                cp -d $source/src/.libs/lib* $INSTALL_DIR/lib
                cp -d $source/src/libczmq.pc $INSTALL_DIR/lib/pkgconfig
                ;;
            *)
                make
                make install
                ;;
            esac
            ;;
        cmake)
            $BUILD_CROSS && {
                config_opts+=(-DCMAKE_SYSTEM_NAME=Linux)
                config_opts+=(-DCMAKE_C_COMPILER=$CC)
                config_opts+=(-DCMAKE_CXX_COMPILER=$CXX)
            }
            # Set library generation rules
            case "$MODE_FLAG" in
            static) config_opts+=("-DCZMQ_BUILD_SHARED=OFF -DCZMQ_BUILD_STATIC=ON") ;;
            share) config_opts+=("-DCZMQ_BUILD_SHARED=ON -DCZMQ_BUILD_STATIC=OFF") ;;
            both) config_opts+=("-DCZMQ_BUILD_SHARED=ON -DCZMQ_BUILD_STATIC=ON") ;; esac
            config_opts+=("-DOPTIONAL_LIBRARIES=\"-lsodium -lstdc++ -lm\"")
            config_opts+=(-DCMAKE_BUILD_TYPE=release)
            config_opts+=("-DCMAKE_INSTALL_PREFIX=\"$INSTALL_DIR\"")
            config_opts+=(-DENABLE_DRAFTS=no)
            mkdir build && cd build
            exec_echo cmake ../ ${config_opts[*]}
            $JUST_TEST && return 0
            make
            make install
            ;;
        esac
        return 0
        ;;
    esac
    . $PROJ_ROOT/common
}
TAG_LIST="autoconf cmake" # All supported user custom tags(empty is allowed)
CUSTOM_TAG="cmake"        # Set default user tag if not specified(Empty is Supported)
proj_init_handler() {
    libuuid_src="$PROJ_ROOT/tarball/libuuid-1.0.3.tar.gz"
    liblz4_src="$PROJ_ROOT/tarball/lz4-1.9.2.tar.gz"
    libsodium_src="$PROJ_ROOT/tarball/libsodium-1.0.18.tar.gz"
    libmicrohttpd_src="$PROJ_ROOT/tarball/libmicrohttpd-0.9.70.tar.gz"
    systemd_src="$PROJ_ROOT/tarball/systemd-245.tar.gz"
    libzmq_src="$PROJ_ROOT/tarball/zeromq-4.3.2.tar.gz"
    libczmq_src="$PROJ_ROOT/tarball/czmq-4.2.0.tar.gz"
}
# Initialize the project and configure compilation parameters
proj_init
load_deps_proj $PROJ_ROOT/build_curl.sh
proj_build libsodium
proj_build libuuid
proj_build libzmq
proj_build liblz4
proj_build libmicrohttpd
# proj_build systemd
proj_build libczmq
proj_pack
