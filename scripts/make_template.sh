#!/bin/bash
set -Ee
set +x
PROJ_ROOT=$(pwd)
. $(dirname ${BASH_SOURCE[0]})/utils
test $# -ne 2 && {
    cat <<EOF
Usage:
    Universal multi-platform quick compile tools. run $(basename $0) to quickly create your own compile script.
    $0 [template name] [tarball Path]
EOF
    exit 1
}
TEMPLATE_NAME=$1
TARBALL_PATH=$2
TARBALL_NAME=$(basename $TARBALL_PATH)
TARBALL_VER=$(guess_tarball_version $TARBALL_PATH)
sed -r \
    -e "s/@TEMPLATE_NAME@/${TEMPLATE_NAME}/g" \
    -e "s/@TARBALL_VER@/${TARBALL_VER}/g" \
    -e "s/@TARBALL_NAME@/${TARBALL_NAME}/g" \
    >$PROJ_ROOT/build_$TEMPLATE_NAME.sh \
    <<'EOF'
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
    @TEMPLATE_NAME@)
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
    esac
    . $PROJ_ROOT/common
}
TAG_LIST="1.x.x @TARBALL_VER@" # All supported user custom tags(empty is allowed)
CUSTOM_TAG="@TARBALL_VER@"     # Set default user tag if not specified(Empty is Supported)
proj_init_handler() {
    @TEMPLATE_NAME@_src="$PROJ_ROOT/tarball/@TEMPLATE_NAME@-default.tar.gz"
    case "$CUSTOM_TAG" in
    1.x.x)
        @TEMPLATE_NAME@_src="$PROJ_ROOT/tarball/@TEMPLATE_NAME@-1.x.x.tar.gz"
        ;;
    @TARBALL_VER@)
        @TEMPLATE_NAME@_src="$PROJ_ROOT/tarball/@TARBALL_NAME@"
        ;;
    esac
    BUILD_PREFER="autoconf" # Build system selection 'autoconf(default)/cmake'
}
# Initialize the project and configure compilation parameters
proj_init
# load_deps_proj $PROJ_ROOT/build_xxx.sh v1.0
proj_build @TEMPLATE_NAME@ # Compilation mode specified by the user[static(default)/share/both]
# proj_build @TEMPLATE_NAME@-static # Force compile static library for current module
# proj_build @TEMPLATE_NAME@-share  # Force compile share library for current module
# proj_build @TEMPLATE_NAME@-both   # Force compile static and share library for current module
proj_pack
EOF
echo "   Target name: $TEMPLATE_NAME"
echo "   Source path: $TARBALL_PATH"
echo " Absolute path: $PROJ_ROOT/tarball/$TARBALL_NAME"
echo "   Source name: $TARBALL_NAME"
echo "Source version: $TARBALL_VER"
test ! -f "$PROJ_ROOT/tarball/$TARBALL_NAME" && {
    echo -e "\033[4;40;33mWARNING: The tarball file is not in the specified directory: [$PROJ_ROOT/tarball/$TARBALL_NAME], copy [$TARBALL_PATH] to here.\033[0m"
    mkdir -p $PROJ_ROOT/tarball
    cp $TARBALL_PATH $PROJ_ROOT/tarball/
}
chmod u+x $PROJ_ROOT/build_$TEMPLATE_NAME.sh
echo -e "\033[0;42;30mDisplay: \033[0m"
cat $PROJ_ROOT/build_$TEMPLATE_NAME.sh
echo -e "\033[0;42;30mCreated $TEMPLATE_NAME template Successfully.\033[0m"
