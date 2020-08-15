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
    libuuid | fribidi | libiconv | libass)
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
    libxml2)
        # Set library generation rules
        case "$MODE_FLAG" in
        static) config_opts+=("--enable-shared=no --enable-static=yes") ;;
        share) config_opts+=("--enable-shared=yes --enable-static=no") ;;
        both) config_opts+=("--enable-shared=yes --enable-static=yes") ;; esac
        $BUILD_CROSS && config_opts+=(--host=$BUILD_HOST)
        config_opts+=(--with-pic)
        config_opts+=(--with-python=no)
        config_opts+=(--prefix=$INSTALL_DIR)
        exec_echo ./configure ${config_opts[*]}
        $JUST_TEST && return 0
        make && make install
        return 0
        ;;
    libpng)
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
        make && make install
        return 0
        ;;
    freetype)
        # Set library generation rules
        case "$MODE_FLAG" in
        static) config_opts+=("--enable-shared=no --enable-static=yes") ;;
        share) config_opts+=("--enable-shared=yes --enable-static=no") ;;
        both) config_opts+=("--enable-shared=yes --enable-static=yes") ;; esac
        $BUILD_CROSS && config_opts+=(--host=$BUILD_HOST)
        config_opts+=(--with-pic)
        config_opts+=(--with-zlib=yes)
        config_opts+=(--with-bzip2=yes)
        config_opts+=(--with-png=yes)
        config_opts+=(--with-harfbuzz=no)
        config_opts+=(--prefix=$INSTALL_DIR)
        exec_echo ./configure ${config_opts[*]}
        $JUST_TEST && return 0
        make && make install
        return 0
        ;;
    harfbuzz)
        # Set library generation rules
        case "$MODE_FLAG" in
        static) config_opts+=("--enable-shared=no --enable-static=yes") ;;
        share) config_opts+=("--enable-shared=yes --enable-static=no") ;;
        both) config_opts+=("--enable-shared=yes --enable-static=yes") ;; esac
        $BUILD_CROSS && config_opts+=(--host=$BUILD_HOST)
        config_opts+=(--with-pic)
        config_opts+=(--with-glib=no)
        config_opts+=(--with-fontconfig=yes)
        config_opts+=(--with-freetype=yes)
        exec_echo ./configure ${config_opts[*]}
        $JUST_TEST && return 0
        make && make install
        return 0
        ;;
    libunwind)
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
    fontconfig)
        type gperf >/dev/null || fatal "Command '$gperf' not found in your system, it required by '$name'."
        # Set library generation rules
        case "$MODE_FLAG" in
        static) config_opts+=("--enable-shared=no --enable-static=yes") ;;
        share) config_opts+=("--enable-shared=yes --enable-static=no") ;;
        both) config_opts+=("--enable-shared=yes --enable-static=yes") ;; esac
        $BUILD_CROSS && config_opts+=(--host=$BUILD_HOST)
        config_opts+=(--enable-libxml2)
        config_opts+=(--with-pic)
        config_opts+=(--prefix=$INSTALL_DIR)
        # config_opts+=("LIBS=\"-lunwind\"")
        exec_echo ./configure ${config_opts[*]}
        $JUST_TEST && return 0
        make && make install
        return 0
        ;;
    sdl2)
        if [ "$PLATFORM" = "android-ndk-r21" ]; then
            mkdir $source/android-project/app/jni/SDL
            cp -r $source/include $source/android-project/app/jni/SDL
            cp -r $source/src $source/android-project/app/jni/SDL
            cp $source/Android.mk $source/android-project/app/jni/SDL
            # cp $sdl2_demo $source/android-project/app/jni/src # build demo
            rm -fr $source/android-project/app/jni/src # delete demo, not to build
            sed -ri "s#^APP_ABI := (.*)#APP_ABI := $DEV_ARCH#" $source/android-project/app/jni/Application.mk
            sed -ri "s#^APP_PLATFORM=(.*)#APP_PLATFORM=android-$ANDROID_API#" $source/android-project/app/jni/Application.mk
            exec_echo $NDK/ndk-build -C $source/android-project/app/jni
            $JUST_TEST && return 0
            mkdir -p $INSTALL_DIR/lib
            cp $source/android-project/app/libs/$DEV_ARCH/* $INSTALL_DIR/lib
            mkdir -p $INSTALL_DIR/include
            cp $source/include/* $INSTALL_DIR/include
        else
            $BUILD_CROSS && config_opts+=(--host=$BUILD_HOST)
            # Set library generation rules
            case "$MODE_FLAG" in
            static) config_opts+=("--enable-shared=no --enable-static=yes") ;;
            share) config_opts+=("--enable-shared=yes --enable-static=no") ;;
            both) config_opts+=("--enable-shared=yes --enable-static=yes") ;; esac
            config_opts+=(--with-pic --enable-sdl2-config)
            config_opts+=(--prefix=$INSTALL_DIR)
            exec_echo ./configure ${config_opts[*]}
            $JUST_TEST && return 0
            make
            make install
        fi
        return 0
        ;;
    ffmpeg)
        local ffmpeg_ver=$(guess_tarball_version $zip)
        test -z "$ffmpeg_ver" && ffmpeg_ver="4.0.0"
        echo_h "FFmpeg source version: $ffmpeg_ver"
        # Set library generation rules
        case "$MODE_FLAG" in
        static) config_opts+=("--enable-static --disable-shared") ;;
        share) config_opts+=("--disable-static --enable-shared") ;;
        both) config_opts+=("--enable-static --enable-shared") ;; esac
        config_opts+=(--extra-version="${PLATFORM}-${DEV_ARCH}")
        config_opts+=(--prefix=$INSTALL_DIR)
        config_opts+=(--enable-pic)
        config_opts+=(--target-os=$BUILD_OS)
        config_opts+=(--arch=$BUILD_ARCH)
        config_opts+=(--pkg-config=$PKG_CONFIG)
        verge $ffmpeg_ver 4.0.0 && config_opts+=(--pkg-config-flags=\"--static\")
        $BUILD_CROSS && config_opts+=(--enable-cross-compile)
        $BUILD_CROSS && config_opts+=(--cross-prefix=$BUILD_PREFIX)
        $BUILD_CROSS || {
            verge $ffmpeg_ver 4.0.0 && config_opts+=(--disable-x86asm) || config_opts+=(--disable-yasm)
        }
        CFLAGS="$CFLAGS -Wa,--noexecstack -fdata-sections -ffunction-sections -ffast-math -fstrict-aliasing"
        if [ "$CC_TYPE" = "gcc" ] && verlt $($CC -dumpversion) 4.9; then
            echo_w "Current gcc don't have '-fstack-protector-strong' option."
        else
            CFLAGS="$CFLAGS -fstack-protector-strong"
        fi
        LDFLAGS="$LDFLAGS -Wl,--gc-sections -Wl,-z,relro -Wl,-z,now"
        # LDFLAGS="$LDFLAGS -rtlib=compiler-rt -lunwind"
        LDEXEFLAGS="-Wl,--gc-sections -Wl,-z,nocopyreloc -pie -fPIE"
        case "$PLATFORM" in
        android*)
            CFLAGS="$CFLAGS -D__ANDROID_API__=$ANDROID_API -fno-integrated-as"
            config_opts+=(--cpu=$BUILD_CPU)
            config_opts+=(--cc=$CC)
            config_opts+=(--cxx=$CXX)
            config_opts+=(--enable-jni)
            config_opts+=(--enable-indev=android_camera)
            config_opts+=(--enable-mediacodec)
            config_opts+=(--enable-decoder=h264_mediacodec)
            case "$DEV_ARCH" in
            armeabi-v7a)
                CFLAGS="$CFLAGS -march=armv7-a -mtune=cortex-a8 -mfloat-abi=softfp -mfpu=vfpv3-d16"
                LDFLAGS="$LDFLAGS -Wl,--fix-cortex-a8"
                config_opts+=(--enable-neon)
                config_opts+=(--enable-thumb)
                ;;
            arm64-v8a) ;;
            x86)
                # CFLAGS="$CFLAGS -m32 -march=i686 -mtune=intel -mssse3 -mfpmath=sse"
                LDFLAGS="$LDFLAGS -Wl,-z,notext"
                ;;
            x86_64)
                # CFLAGS="$CFLAGS -m64 -march=x86-64 -mtune=intel -msse4.2 -mpopcnt"
                ;;
            esac
            ;;
        esac
        config_opts+=(--extra-cflags=\"$CFLAGS\")
        config_opts+=(--extra-ldflags=\"$LDFLAGS\")
        verge $ffmpeg_ver 4.0.0 && config_opts+=(--extra-ldexeflags=\"$LDEXEFLAGS\")
        case "$CUSTOM_TAG" in
        full)
            # Dependency library support
            config_opts+=(--enable-bzlib)
            config_opts+=(--enable-zlib)
            config_opts+=(--enable-libass)
            config_opts+=(--enable-libxml2)
            config_opts+=(--enable-libfribidi)
            config_opts+=(--enable-libfontconfig)
            config_opts+=(--enable-iconv)
            config_opts+=(--enable-libfreetype)
            config_opts+=(--enable-sdl2)
            # ffmpeg customization
            config_opts+=(--enable-runtime-cpudetect)
            ;;
        lite) ;;
        corelibs)
            # Dependency library support
            config_opts+=(--enable-bzlib)
            config_opts+=(--enable-zlib)
            config_opts+=(--enable-libass)
            config_opts+=(--enable-libxml2)
            config_opts+=(--enable-libfribidi)
            config_opts+=(--enable-libfontconfig)
            config_opts+=(--enable-iconv)
            config_opts+=(--enable-libfreetype)
            # config_opts+=(--enable-sdl2)
            # ffmpeg customization
            config_opts+=(--disable-doc)
            config_opts+=(--disable-htmlpages)
            config_opts+=(--disable-manpages)
            config_opts+=(--disable-podpages)
            config_opts+=(--disable-txtpages)
            config_opts+=(--disable-debug)
            config_opts+=(--disable-programs)
            config_opts+=(--disable-ffmpeg)
            config_opts+=(--disable-ffplay)
            config_opts+=(--disable-ffprobe)
            config_opts+=(--disable-v4l2-m2m)
            config_opts+=(--disable-outdevs)
            config_opts+=(--disable-indevs)
            config_opts+=(--disable-postproc)
            config_opts+=(--enable-runtime-cpudetect)
            ;;
        dlna | dlna-compat)
            config_opts+=(--disable-programs)
            config_opts+=(--disable-ffmpeg)
            config_opts+=(--disable-ffplay)
            config_opts+=(--disable-ffprobe)
            config_opts+=(--disable-doc)
            config_opts+=(--disable-htmlpages)
            config_opts+=(--disable-manpages)
            config_opts+=(--disable-podpages)
            config_opts+=(--disable-txtpages)
            config_opts+=(--disable-avdevice)
            config_opts+=(--disable-swscale)
            config_opts+=(--disable-postproc)
            config_opts+=(--disable-avfilter)
            config_opts+=(--disable-network)
            config_opts+=(--enable-small)
            config_opts+=(--disable-debug)
            config_opts+=(--disable-muxers)
            config_opts+=(--disable-encoders)
            config_opts+=(--disable-parsers)
            config_opts+=(--disable-filters)
            config_opts+=(--disable-devices)
            ;;
        esac
        exec_echo ./configure ${config_opts[*]}
        $JUST_TEST && return 0
        make && make install
        return 0
        ;;
    esac
    . $PROJ_ROOT/common
}
TAG_LIST="full lite corelibs dlna dlna-compat" # All supported user custom tags(empty is allowed)
CUSTOM_TAG="full"                              # Set default user tag if not specified(Empty is Supported)
proj_init_handler() {
    libz_src="$PROJ_ROOT/tarball/zlib-1.2.11.tar.xz"
    libiconv_src="$PROJ_ROOT/tarball/libiconv-1.15.tar.gz"
    libpng_src="$PROJ_ROOT/tarball/libpng-1.6.35.tar.xz"
    harfbuzz_src="$PROJ_ROOT/tarball/harfbuzz-2.1.1.tar.bz2"
    bzip2_src="$PROJ_ROOT/tarball/bzip2-1.0.6.tar.gz"
    freetype_src="$PROJ_ROOT/tarball/freetype-2.9.1.tar.gz"
    libuuid_src="$PROJ_ROOT/tarball/libuuid-1.0.3.tar.gz"
    libxml2_src="$PROJ_ROOT/tarball/libxml2-2.9.8.tar.gz"
    libunwind_src="$PROJ_ROOT/tarball/libunwind-1.4.0.tar.gz"
    fontconfig_src="$PROJ_ROOT/tarball/fontconfig-2.13.0.tar.gz"
    fribidi_src="$PROJ_ROOT/tarball/fribidi-1.0.5.tar.bz2"
    libass_src="$PROJ_ROOT/tarball/libass-0.14.0.tar.gz"
    sdl2_src="$PROJ_ROOT/tarball/SDL2-2.0.12.tar.gz"
    ffmpeg_src="$PROJ_ROOT/tarball/ffmpeg-4.2.3.tar.bz2"
    case "$PLATFORM-$DEV_ARCH" in
    android*-armeabi-v7a) ANDROID_API=21 ;;
    arm64-v8a) ANDROID_API=21 ;;
    x86) ANDROID_API=21 ;;
    x86_64) ANDROID_API=21 ;; esac

    case "$CUSTOM_TAG" in
    full | lite | corelibs) ;;
    dlna) ffmpeg_src="$PROJ_ROOT/tarball/ffmpeg-4.0.3.tar.xz" ;;
    dlna-compat) ffmpeg_src="$PROJ_ROOT/tarball/ffmpeg-2.2.16.tar.bz2" ;; esac
}
# Initialize the project and configure compilation parameters
proj_init
case "$CUSTOM_TAG" in
full | corelibs)
    proj_build bzip2-static
    proj_build libz libiconv fribidi libpng libuuid libxml2
    proj_build freetype
    proj_build fontconfig libass
    proj_build sdl2
    proj_build ffmpeg-share
    ;;
lite)
    proj_build ffmpeg-share
    ;;
dlna | dlna-compat)
    proj_build libz ffmpeg
    ;;
esac
