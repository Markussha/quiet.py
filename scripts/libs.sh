#!/usr/bin/env bash
set -e

ABSPATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd)"
SCRIPTPATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)"
SRCPATH="$ABSPATH"
SYSROOTPATH="$ABSPATH/sysroot"
LIBPATH="$ABSPATH/lib/"
INCLUDEPATH="$ABSPATH/include/"

if [ ! -d "$SYSROOTPATH/usr" ]; then
    mkdir -p "$SYSROOTPATH/usr"
fi

export SYSROOT="$SYSROOTPATH"
BUILDPATH="$SCRIPTPATH/build"
mkdir -p "$BUILDPATH"

mkdir -p "$BUILDPATH/libcorrect"
cd "$BUILDPATH/libcorrect"
cmake -DCMAKE_BUILD_TYPE=Release "$SRCPATH/libcorrect" -DCMAKE_INSTALL_PREFIX="$SYSROOT/usr" && make && make shim && make install
rm -f "$SYSROOT/usr/lib/libfec.dylib"

mkdir -p "$BUILDPATH/liquid-dsp"
cd "$BUILDPATH/liquid-dsp"
cmake -DCMAKE_BUILD_TYPE=Release "$SRCPATH/liquid-dsp" -DCMAKE_C_FLAGS="-fPIC" -DLIQUID_FFTOVERRIDE=ON -DCMAKE_INSTALL_PREFIX="$SYSROOT/usr" -DCMAKE_PREFIX_PATH="$SYSROOT" -DCMAKE_SHARED_LINKER_FLAGS="-L$SYSROOT/usr/lib" -DLIQUID_BUILD_EXAMPLES="off" -DLIQUID_BUILD_SANDBOX="off" && make liquid-static && make install

mkdir -p "$BUILDPATH/jansson"
cd "$BUILDPATH/jansson"
cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$SYSROOT/usr" -DJANSSON_BUILD_SHARED_LIBS=off -DJANSSON_WITHOUT_TESTS=on -DJANSSON_EXAMPLES=off -DJANSSON_BUILD_DOCS=off "$SRCPATH/jansson" && make && make install

# mkdir -p "$BUILDPATH/portaudio"
# cd "$BUILDPATH/portaudio"
# cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_FLAGS="-fPIC" -DCMAKE_INSTALL_PREFIX="$SYSROOT/usr" -DCMAKE_PREFIX_PATH="$SYSROOT" "$SRCPATH/portaudio" && make && make install && cp libportaudio_static.a "$SYSROOT/usr/lib/libportaudio.a"

mkdir -p "$BUILDPATH/libquiet"
cd "$BUILDPATH/libquiet"
cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_FLAGS="-fPIC" -DCMAKE_INSTALL_PREFIX="$SYSROOT/usr" -DCMAKE_PREFIX_PATH="$SYSROOT" "$SRCPATH/libquiet" && make quiet quiet-profiles || true
make install

mkdir -p "$LIBPATH"
mkdir -p "$INCLUDEPATH"
cp "$SYSROOTPATH/usr/lib/libfec.a" "$LIBPATH"
cp "$SYSROOTPATH/usr/lib/libliquid.a" "$LIBPATH"
cp "$SYSROOTPATH/usr/lib/libjansson.a" "$LIBPATH"
# cp "$SYSROOTPATH/usr/lib/libportaudio.a" "$LIBPATH"
cp "$SYSROOTPATH/usr/lib/libquiet.a" "$LIBPATH"
cp "$SYSROOTPATH/usr/include/fec.h" "$INCLUDEPATH"
cp -R "$SYSROOTPATH/usr/include/liquid" "$INCLUDEPATH"
cp "$SYSROOTPATH/usr/include/jansson.h" "$INCLUDEPATH"
cp "$SYSROOTPATH/usr/include/jansson_config.h" "$INCLUDEPATH"
# cp "$SYSROOTPATH/usr/include/portaudio.h" "$INCLUDEPATH"
cp "$SYSROOTPATH/usr/include/quiet.h" "$INCLUDEPATH"

if [ "$(uname)" == "Darwin" ]; then
gcc -shared -o $ABSPATH/quiet/libquiet.so \
-Wl,-all_load $LIBPATH/libquiet.a $LIBPATH/libliquid.a $LIBPATH/libfec.a \
$LIBPATH/libjansson.a -Wl,-noall_load
else
gcc -shared -o $ABSPATH/quiet/libquiet.so \
-Wl,--whole-archive $LIBPATH/libquiet.a  -Wl,--no-whole-archive $LIBPATH/libliquid.a $LIBPATH/libfec.a \
$LIBPATH/libjansson.a
fi


echo
echo "Build complete. Built libraries are in $LIBPATH"
echo "and includes in $INCLUDEPATH."
