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
    lzma | libuuid | libffi)
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
    ncurses)
        # Set library generation rules
        case "$MODE_FLAG" in
        static) config_opts+=("--enable-shared=no --enable-static=yes") ;;
        share) config_opts+=("--enable-shared=yes --enable-static=no") ;;
        both) config_opts+=("--enable-shared=yes --enable-static=yes") ;; esac
        $BUILD_CROSS && config_opts+=(--host=$BUILD_HOST)
        $BUILD_CROSS && config_opts+=(--disable-stripping)
        config_opts+=(--with-pic)
        config_opts+=(--prefix=$INSTALL_DIR)
        exec_echo ./configure ${config_opts[*]}
        $JUST_TEST && return 0
        make && make install
        return 0
        ;;
    sqlite3)
        # Set library generation rules
        case "$MODE_FLAG" in
        static) config_opts+=("--enable-shared=no --enable-static=yes") ;;
        share) config_opts+=("--enable-shared=yes --enable-static=no") ;;
        both) config_opts+=("--enable-shared=yes --enable-static=yes") ;; esac
        $BUILD_CROSS && config_opts+=(--host=$BUILD_HOST)
        config_opts+=(--with-pic)
        config_opts+=("LIBS=\"-lreadline\"")
        config_opts+=(--prefix=$INSTALL_DIR)
        exec_echo ./configure ${config_opts[*]}
        $JUST_TEST && return 0
        make && make install
        return 0
        ;;
    libnsl)
        autoreconf -fi
        # Set library generation rules
        case "$MODE_FLAG" in
        static) config_opts+=("--enable-shared=no --enable-static=yes") ;;
        share) config_opts+=("--enable-shared=yes --enable-static=no") ;;
        both) config_opts+=("--enable-shared=yes --enable-static=yes") ;; esac
        $BUILD_CROSS && config_opts+=(--host=$BUILD_HOST)
        config_opts+=(--with-pic)
        config_opts+=(--prefix=$INSTALL_DIR)
        config_opts+=(--sysconfdir=$INSTALL_DIR/etc)
        exec_echo ./configure ${config_opts[*]}
        $JUST_TEST && return 0
        make && make install
        return 0
        ;;
    gdbm)
        # Set library generation rules
        case "$MODE_FLAG" in
        static) config_opts+=("--enable-shared=no --enable-static=yes") ;;
        share) config_opts+=("--enable-shared=yes --enable-static=no") ;;
        both) config_opts+=("--enable-shared=yes --enable-static=yes") ;; esac
        case "$PLATFORM-$DEV_ARCH" in
        Dev-Dev01 | Dev-Dev03) export CFLAGS="-D_XOPEN_SOURCE=500 $CFLAGS" ;; esac
        $BUILD_CROSS && config_opts+=(--host=$BUILD_HOST)
        config_opts+=(--with-pic)
        config_opts+=(--enable-libgdbm-compat)
        config_opts+=(--prefix=$INSTALL_DIR)
        exec_echo ./configure ${config_opts[*]}
        $JUST_TEST && return 0
        make && make install
        return 0
        ;;
    tcl | tk)
        cd unix
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
    readline)
        # Set library generation rules
        case "$MODE_FLAG" in
        static) config_opts+=("--enable-shared=no --enable-static=yes") ;;
        share) config_opts+=("--enable-shared=yes --enable-static=no") ;;
        both) config_opts+=("--enable-shared=yes --enable-static=yes") ;; esac
        export CFLAGS="-fPIC $CFLAGS"
        $BUILD_CROSS && config_opts+=(--host=$BUILD_HOST)
        config_opts+=(--with-pic)
        config_opts+=(--prefix=$INSTALL_DIR)
        exec_echo ./configure ${config_opts[*]}
        $JUST_TEST && return 0
        make && make install
        return 0
        ;;
    python)
        export CFLAGS="-pthread $CFLAGS"
        export CPPFLAGS="$CPPFLAGS -I$INSTALL_DIR/include/ncurses -I$INSTALL_DIR/include/uuid"
        $BUILD_CROSS && {
            config_opts+=(--host=$BUILD_HOST)
            config_opts+=(--build=$(uname -m)-linux-gnu)
            config_opts+=(--disable-ipv6)
            config_opts+=(ac_cv_file__dev_ptmx=yes)
            config_opts+=(ac_cv_file__dev_ptc=no)
        }
        config_opts+=(--disable-shared)
        config_opts+=(--with-pic)
        config_opts+=("LIBS=\"-lpthread\"")
        config_opts+=(--prefix=$INSTALL_DIR)
        exec_echo ./configure ${config_opts[*]}
        $JUST_TEST && return 0
        make && make install
        return 0
        ;;
    speedtest)
        # $INSTALL_DIR/bin/python3 setup.py install
        $JUST_TEST && return 0
        cp ./speedtest.py $INSTALL_DIR/bin/
        sed -i 'N;30a\import ssl\nssl._create_default_https_context = ssl._create_unverified_context' $INSTALL_DIR/bin/speedtest.py
        return 0
        ;;
    esac
    . $PROJ_ROOT/common
}
proj_pack_hanlder() {
    local src_dir=$1
    local dst_dir=$2
    mkdir -p $dst_dir/bin && cp -rd $src_dir/bin/py* $dst_dir/bin
    cp -rd $src_dir/bin/speedtest* $dst_dir/bin
    mkdir -p $dst_dir/lib && cp -rd $src_dir/lib/py* $dst_dir/lib
}
TAG_LIST="2.7 3.8" # All supported user custom tags(empty is allowed)
CUSTOM_TAG="3.8"   # Set default user tag if not specified(Empty is Supported)
proj_init_handler() {
    bzip2_src="$PROJ_ROOT/tarball/bzip2-1.0.6.tar.gz"
    libz_src="$PROJ_ROOT/tarball/zlib-1.2.11.tar.xz"
    libuuid_src="$PROJ_ROOT/tarball/libuuid-1.0.3.tar.gz"
    libnsl_src="$PROJ_ROOT/tarball/libnsl-1.2.0.tar.gz"
    sqlite3_src="$PROJ_ROOT/tarball/sqlite-autoconf-3310100.tar.gz"
    libffi_src="$PROJ_ROOT/tarball/libffi-3.3.tar.gz"
    lzma_src="$PROJ_ROOT/tarball/xz-5.2.4.tar.gz"
    gdbm_src="$PROJ_ROOT/tarball/gdbm-1.18.1.tar.gz"
    tcl_src="$PROJ_ROOT/tarball/tcl8.6.10-src.tar.gz"
    tk_src="$PROJ_ROOT/tarball/tk8.6.10-src.tar.gz"
    readline_src="$PROJ_ROOT/tarball/readline-8.0.tar.gz"
    ncurses_src="$PROJ_ROOT/tarball/ncurses-6.2.tar.gz"
    openssl_src="$PROJ_ROOT/tarball/openssl-1.1.1d.tar.gz"
    speedtest_src="$PROJ_ROOT/tarball/speedtest-cli-2.1.2.tar.gz"
    case "$CUSTOM_TAG" in
    "2.7")
        python_src="$PROJ_ROOT/tarball/Python-2.7.17.tar.xz"
        ;;
    "3.8")
        python_src="$PROJ_ROOT/tarball/Python-3.8.1.tar.xz"
        ;;
    esac
}
# Initialize the project and configure compilation parameters
proj_init
proj_build libz bzip2 lzma libuuid openssl
# proj_build ncurses #failed
proj_build readline gdbm libffi sqlite3
# proj_build tcl tk #failed
# proj_build libnsl #failed
proj_build python
proj_build speedtest
proj_pack
