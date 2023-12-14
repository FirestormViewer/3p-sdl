#!/usr/bin/env bash

# turn on verbose debugging output for parabuild logs.
exec 4>&1; export BASH_XTRACEFD=4; set -x
# make errors fatal
set -e
# bleat on references to undefined shell variables
set -u

TOP="$(dirname "$0")"

SDL_SOURCE_DIR="SDL2-2.28.5"
SDL_VERSION=$(sed -n -e 's/^Version: //p' "$TOP/$SDL_SOURCE_DIR/SDL2.spec")

if [ -z "$AUTOBUILD" ] ; then 
    exit 1
fi

if [ "$OSTYPE" = "cygwin" ] ; then
    export AUTOBUILD="$(cygpath -u $AUTOBUILD)"
fi

stage="$(pwd)"

# load autobuild provided shell functions and variables
source_environment_tempfile="$stage/source_environment.sh"
"$AUTOBUILD" source_environment > "$source_environment_tempfile"
. "$source_environment_tempfile"

case "$AUTOBUILD_PLATFORM" in

    linux64)
        # Default target per autobuild --address-size
        opts="${TARGET_OPTS:--m$AUTOBUILD_ADDRSIZE $LL_BUILD_RELEASE}"

        # Handle any deliberate platform targeting
        if [ -z "${TARGET_CPPFLAGS:-}" ]; then
            # Remove sysroot contamination from build environment
            unset CPPFLAGS
        else
            # Incorporate special pre-processing flags
            export CPPFLAGS="$TARGET_CPPFLAGS"
        fi

        pushd "$TOP/$SDL_SOURCE_DIR"
            # do release build of sdl
              CFLAGS="$opts" CXXFLAGS="$opts" CPPFLAGS="$opts" \
              LDFLAGS="-L$stage/packages/lib/release -L$stage/lib/release $opts" \
                ./configure --with-pic \
                --prefix="$stage" --libdir="$stage/lib/release" --includedir="$stage/include"
            make -j4
            make install

            # clean the build tree
            make distclean
        popd
    ;;

    *)
        echo "Unrecognized platform $AUTOBUILD_PLATFORM" 1>&2
        exit -1
    ;;
esac

mkdir -p "$stage/LICENSES"
cp "$TOP/$SDL_SOURCE_DIR/LICENSE.txt" "$stage/LICENSES/SDL.txt"
mkdir -p "$stage"/docs/SDL/
cp -a "$TOP"/README.Linden "$stage"/docs/SDL/
echo "$SDL_VERSION" > "$stage/VERSION.txt"
