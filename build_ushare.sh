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
    libdlna)
        $BUILD_CROSS && {
            # 解决libdlna库configure文件的bug
            # 根据压缩包文件名获取版本号
            local libdlna_version=$(echo $zip | sed -rn "s/.*-([0-9]+\.[0-9]+\.[0-9]+).*/\1/p")
            # 判断正则表达式是否正确解析版本号
            test -z "$libdlna_version" && fatal "$name version parse error: $libdlna_version"
            # 解决configure文件的bug，由于交叉编译，configure文件中获取版本号
            # 的代码无法执行，因此这里直接手动写入版本号
            sed -i "s/VERSION=\`\$TMPE\`/VERSION=\"$libdlna_version\"/g" configure
        }
        sed -i "s/-lavformat/-lavformat -lavcodec -lswresample -lavutil -lz -lpthread -lm/g" configure
        export CFLAGS="$CFLAGS -I$INSTALL_DIR/include"
        export LDFLAGS="$LDFLAGS -lavformat -lavcodec -lswresample -lavutil -lz"
        $BUILD_CROSS && {
            config_opts+=(--cross-prefix=$BUILD_PREFIX)
            config_opts+=(--cross-compile)
        }
        # Set library generation rules
        case "$MODE_FLAG" in
        static) config_opts+=("--enable-static --disable-shared") ;;
        share) config_opts+=("--disable-static --enable-shared") ;;
        both) config_opts+=("--enable-static --enable-shared") ;; esac
        config_opts+=(--with-ffmpeg-dir=$INSTALL_DIR)
        config_opts+=(--disable-developer)
        config_opts+=(--disable-debug)
        config_opts+=(--prefix=$INSTALL_DIR)
        exec_echo ./configure ${config_opts[*]}
        $JUST_TEST && return 0
        make && make install
        return 0
        ;;
    libupnp)
        # Unable to recognize 'aarch64' architecture, update configuration file.
        if [ "$(echo $BUILD_HOST | grep "aarch64" | wc -l)" -eq 1 ]; then
            cd build-aux && {
                wget -O config.guess 'http://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.guess;hb=HEAD'
                wget -O config.sub 'http://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.sub;hb=HEAD'
            } && cd ..
        fi
        export CFLAGS="$CFLAGS -D_FILE_OFFSET_BITS=64"
        $BUILD_CROSS && config_opts+=(--host=$BUILD_HOST)
        # Set library generation rules
        case "$MODE_FLAG" in
        static) config_opts+=("--enable-shared=no --enable-static=yes") ;;
        share) config_opts+=("--enable-shared=yes --enable-static=no") ;;
        both) config_opts+=("--enable-shared=yes --enable-static=yes") ;; esac
        config_opts+=(--prefix=$INSTALL_DIR)
        exec_echo ./configure ${config_opts[*]}
        $JUST_TEST && return 0
        make && make install
        return 0
        ;;
    ushare)
        sed -i '/.*Checking for libupnp.*/a\extralibs="-lupnp $extralibs"' configure
        sed -i '/.*Checking for libdlna.*/a\ extralibs="-ldlna -lavformat -lavcodec -lswresample -lavutil -lz -lm $extralibs"' configure
        export CFLAGS="$CFLAGS -I$source -I$INSTALL_DIR/include -fgnu89-inline -Wno-unused-parameter"
        $BUILD_CROSS && {
            config_opts+=(--cross-prefix=$BUILD_PREFIX)
            config_opts+=(--cross-compile)
            config_opts+=(--disable-nls)
        }
        config_opts+=(--enable-dlna)
        config_opts+=(--with-libupnp-dir=$INSTALL_DIR)
        config_opts+=(--with-libdlna-dir=$INSTALL_DIR)
        config_opts+=(--prefix=$INSTALL_DIR)
        exec_echo ./configure ${config_opts[*]}
        $JUST_TEST && return 0
        make && make install
        cp $INSTALL_DIR/etc/ushare.conf $INSTALL_DIR/bin
        strip_so $INSTALL_DIR/bin/ushare
        return 0
        ;;
    esac
    . $PROJ_ROOT/common
}

proj_pack_hanlder() {
    local src_dir=$1
    local dst_dir=$2
    if [ $(ls $src_dir/lib/lib*.so* 2>/dev/null | wc -l) -ne 0 ]; then
        mkdir -p $dst_dir/lib
        cp -d $src_dir/lib/lib*.so* $dst_dir/lib
    fi
    cp -r $src_dir/bin/ushare $dst_dir
    cp -r $src_dir/etc/ushare.conf $dst_dir
}
TAG_LIST="patch origin" # All supported user custom tags(empty is allowed)
CUSTOM_TAG="patch"      # Set default user tag if not specified(Empty is Supported)
proj_init_handler() {
    case "$CUSTOM_TAG" in
    origin)
        libdlna_src="$PROJ_ROOT/tarball/libdlna-0.2.4.tar.bz2"
        libupnp_src="$PROJ_ROOT/tarball/libupnp-1.6.5.tar.bz2"
        ushare_src="$PROJ_ROOT/tarball/ushare-1.1a.tar.bz2"
        ;;
    patch)
        libdlna_src="$PROJ_ROOT/tarball/libdlna-0.2.4-patch.tar.bz2"
        libupnp_src="$PROJ_ROOT/tarball/libupnp-1.6.24-patch.tar.bz2"
        ushare_src="$PROJ_ROOT/tarball/ushare-1.1a-patch.tar.bz2"
        ;;
    esac
}
# Initialize the project and configure compilation parameters
proj_init
case "$CUSTOM_TAG" in
origin) load_deps_proj $PROJ_ROOT/build_ffmpeg.sh dlna-compat ;;
patch) load_deps_proj $PROJ_ROOT/build_ffmpeg.sh dlna ;; esac
proj_build libupnp libdlna
proj_build ushare
proj_pack
