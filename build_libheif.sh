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
    libjpeg)
        # Set library generation rules
        case "$MODE_FLAG" in
        static) config_opts+=("--enable-shared=no --enable-static=yes") ;;
        share) config_opts+=("--enable-shared=yes --enable-static=no") ;;
        both) config_opts+=("--enable-shared=yes --enable-static=yes") ;; esac
        # Linker parameters: '-s' strip, '-static' static link.
        export LDFLAGS="$LDFLAGS -s -static"
        # libtool link mode: make a program do not link it against any shared libraries at all.
        # export LDFLAGS="$LDFLAGS -all-static"
        $BUILD_CROSS && config_opts+=(--host=$BUILD_HOST)
        config_opts+=(--with-pic)
        config_opts+=(--prefix=$INSTALL_DIR)
        exec_echo ./configure ${config_opts[*]}
        $JUST_TEST && return 0
        make && make install
        return 0
        ;;
    libpng)
        case "$CUSTOM_TAG" in
        autoconf)
            # Set library generation rules
            case "$MODE_FLAG" in
            static) config_opts+=("--enable-shared=no --enable-static=yes") ;;
            share) config_opts+=("--enable-shared=yes --enable-static=no") ;;
            both) config_opts+=("--enable-shared=yes --enable-static=yes") ;; esac
            $BUILD_CROSS && config_opts+=(--host=$BUILD_HOST)
            config_opts+=(--with-pic)
            config_opts+=(--enable-hardware-optimizations)
            config_opts+=(--prefix=$INSTALL_DIR)
            exec_echo ./configure ${config_opts[*]}
            $JUST_TEST && return 0
            make
            make install
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
            config_opts+=(-DCMAKE_BUILD_TYPE=release)
            config_opts+=(-DCMAKE_INSTALL_PREFIX=\"$INSTALL_DIR\")
            mkdir _build && cd _build
            exec_echo cmake ../ ${config_opts[*]}
            $JUST_TEST && return 0
            cmake --build .
            cmake --install . --strip
            ;;
        esac
        return 0
        ;;
    libx265)
        # https://bitbucket.org/multicoreware/x265/wiki/Home
        # Set library generation rules
        case "$MODE_FLAG" in
        static) config_opts+=(-DENABLE_SHARED=OFF) ;;
        share) ;& # fallthrough(Since bash 4.0)
        both) config_opts+=(-DENABLE_SHARED=ON) ;; esac
        $BUILD_CROSS && {
            config_opts+=(-DCMAKE_SYSTEM_NAME=Linux)
            config_opts+=(-DCMAKE_C_COMPILER=$CC)
            config_opts+=(-DCMAKE_CXX_COMPILER=$CXX)
        }
        config_opts+=(-DHIGH_BIT_DEPTH=ON)
        # config_opts+=(-DEXPORT_C_API=OFF)
        config_opts+=(-DENABLE_CLI=OFF)
        config_opts+=(-DMAIN12=ON)
        config_opts+=(-DCMAKE_BUILD_TYPE=release)
        config_opts+=(-Wno-dev)
        config_opts+=(-DCMAKE_INSTALL_PREFIX=\"$INSTALL_DIR\")
        mkdir -p _build && cd _build
        test -f "CMakeLists.txt" && echo -e "\nCMakeLists.txt: \n" >>$config_help &&
            cmake ../source -L >>$config_help
        exec_echo cmake ../source ${config_opts[*]}
        $JUST_TEST && return 0
        cmake --build .
        cmake --install . --strip
        return 0
        ;;
    libde265)
        case "$CUSTOM_TAG" in
        autoconf)
            # Set library generation rules
            case "$MODE_FLAG" in
            static) config_opts+=("--enable-shared=no --enable-static=yes") ;;
            share) config_opts+=("--enable-shared=yes --enable-static=no") ;;
            both) config_opts+=("--enable-shared=yes --enable-static=yes") ;; esac
            # Linker parameters: '-s' strip, '-static' static link.
            export LDFLAGS="$LDFLAGS -s -static"
            # libtool link mode: make a program do not link it against any shared libraries at all.
            # export LDFLAGS="$LDFLAGS -all-static"
            $BUILD_CROSS && config_opts+=(--host=$BUILD_HOST)
            config_opts+=(--with-pic)
            config_opts+=(--prefix=$INSTALL_DIR)
            config_opts+=(--disable-encoder)
            config_opts+=(--disable-dec265)
            config_opts+=(--disable-sherlock265)
            exec_echo ./configure ${config_opts[*]}
            $JUST_TEST && return 0
            make && make install
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
            config_opts+=(-DCMAKE_BUILD_TYPE=release)
            config_opts+=(-DCMAKE_INSTALL_PREFIX=\"$INSTALL_DIR\")
            mkdir _build && cd _build
            exec_echo cmake ../ ${config_opts[*]}
            $JUST_TEST && return 0
            cmake --build .
            cmake --install . --strip
            ;;
        esac
        return 0
        ;;
    libaom)
        # https://proxies.xuexi.icu/-----https://aomedia.googlesource.com/aom/
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
        config_opts+=(-DCMAKE_INSTALL_PREFIX=\"$INSTALL_DIR\")
        mkdir -p build && cd build
        exec_echo cmake ../ ${config_opts[*]}
        $JUST_TEST && return 0
        cmake --build .
        cmake --install . --strip
        return 0
        ;;
    libheif)
        case "$CUSTOM_TAG" in
        autoconf)
            # Set library generation rules
            case "$MODE_FLAG" in
            static) config_opts+=("--enable-shared=no --enable-static=yes") ;;
            share) config_opts+=("--enable-shared=yes --enable-static=no") ;;
            both) config_opts+=("--enable-shared=yes --enable-static=yes") ;; esac
            # Linker parameters: '-s' strip, '-static' static link.
            export LDFLAGS="$LDFLAGS -s -static"
            # libtool link mode: make a program do not link it against any shared libraries at all.
            # export LDFLAGS="$LDFLAGS -all-static"
            # config_opts+=(x265_CFLAGS=\"$($PKG_CONFIG x265 --cflags)\")
            # config_opts+=(x265_LIBS=\"$($PKG_CONFIG x265 --libs) -ldl\")
            $BUILD_CROSS && config_opts+=(--host=$BUILD_HOST)
            config_opts+=(--with-pic)
            config_opts+=(--disable-go)
            config_opts+=(--prefix=$INSTALL_DIR)
            exec_echo ./configure ${config_opts[*]}
            $JUST_TEST && return 0
            make && make install
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
            export CXXFLAGS="$CXXFLAGS -I$INSTALL_DIR/include"
            config_opts+=(-DCMAKE_BUILD_TYPE=release)
            config_opts+=(-DCMAKE_INSTALL_PREFIX=\"$INSTALL_DIR\")
            mkdir _build && cd _build
            exec_echo cmake ../ ${config_opts[*]}
            $JUST_TEST && return 0
            cmake --build .
            cmake --install . --strip
            mkdir -p $INSTALL_DIR/bin && cp examples/heif-* $INSTALL_DIR/bin
            ;;
        esac
        return 0
        ;;
    esac
    . $PROJ_ROOT/common
}
TAG_LIST="autoconf cmake" # All supported user custom tags(empty is allowed)
CUSTOM_TAG="autoconf"     # Set default user tag if not specified(Empty is Supported)
proj_init_handler() {
    libjpeg_src="$PROJ_ROOT/tarball/jpegsrc.v9d.tar.gz"
    libz_src="$PROJ_ROOT/tarball/zlib-1.2.11.tar.xz"
    libpng_src="$PROJ_ROOT/tarball/libpng-1.6.37.tar.xz"
    libde265_src="$PROJ_ROOT/tarball/libde265-1.0.5.tar.gz"
    libx265_src="$PROJ_ROOT/tarball/x265_3.4.tar.gz"
    libaom_src="$PROJ_ROOT/tarball/aom-v2.0.0.tar.gz"
    libheif_src="$PROJ_ROOT/tarball/libheif-1.7.0.tar.gz"
}
# Initialize the project and configure compilation parameters
proj_init
# proj_build libz libpng
proj_build libjpeg
# proj_build libx265
proj_build libde265
# proj_build libaom
proj_build libheif
# proj_pack
