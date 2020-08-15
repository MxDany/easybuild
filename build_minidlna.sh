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
    libiconv | libjpeg | libogg | libvorbis | libFLAC | sqlite3)
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
    libexif | libid3tag)
        # Unable to recognize 'aarch64' architecture, update configuration file.
        if [ "$(echo $BUILD_HOST | grep "aarch64" | wc -l)" -eq 1 ]; then
            wget -O config.guess 'http://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.guess;hb=HEAD'
            wget -O config.sub 'http://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.sub;hb=HEAD'
        fi
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
    minidlna)
        $BUILD_CROSS && config_opts+=(--host=$BUILD_HOST)
        config_opts+=("LIBS=\"-lid3tag -lFLAC -lvorbis -logg -lsqlite3 -lexif -ljpeg -lavformat -lavcodec -lswresample -lavutil -lpthread -lz -ldl -lm\"")
        config_opts+=(--prefix=$INSTALL_DIR)
        exec_echo ./configure ${config_opts[*]}
        $JUST_TEST && return 0
        make && make install
        cp $source/minidlna.conf $INSTALL_DIR/sbin
        strip_so $INSTALL_DIR/sbin/minidlnad
        return 0
        ;;
    esac
    . $PROJ_ROOT/common
}
proj_pack_hanlder() {
    local src_dir=$1
    local dst_dir=$2
    cp -r $src_dir/sbin/minidlnad $dst_dir
    cp -r $src_dir/sbin/minidlna.conf $dst_dir
}
TAG_LIST="patch"   # All supported user custom tags(empty is allowed)
CUSTOM_TAG="patch" # Set default user tag if not specified(Empty is Supported)
proj_init_handler() {
    libexif_src="$PROJ_ROOT/tarball/libexif-0.6.21.tar.bz2"
    libjpeg_src="$PROJ_ROOT/tarball/jpegsrc.v9c.tar.gz"
    libid3tag_src="$PROJ_ROOT/tarball/libid3tag-0.15.1b.tar.gz"
    libFLAC_src="$PROJ_ROOT/tarball/flac-1.3.2.tar.xz"
    libogg_src="$PROJ_ROOT/tarball/libogg-1.3.3.tar.xz"
    libvorbis_src="$PROJ_ROOT/tarball/libvorbis-1.3.6.tar.xz"
    sqlite3_src="$PROJ_ROOT/tarball/sqlite-autoconf-3270200.tar.gz"
    case "$CUSTOM_TAG" in
    patch)
        minidlna_src="$PROJ_ROOT/tarball/minidlna-1.2.1-patch.tar.bz2"
        ;;
    esac
}
# Initialize the project and configure compilation parameters
proj_init
load_deps_proj $PROJ_ROOT/build_ffmpeg.sh dlna
proj_build libexif libjpeg libid3tag libogg libvorbis libFLAC sqlite3
proj_build minidlna
proj_pack
