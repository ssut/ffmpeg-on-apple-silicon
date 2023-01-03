#!/bin/bash
set -exuo pipefail

WORKDIR="$(pwd)/workdir"
mkdir -p ${WORKDIR}

SRC="$WORKDIR/sw"
CMPLD="$WORKDIR/compile"
NUM_PARALLEL_BUILDS=$(sysctl -n hw.ncpu)

if [[ -e "${CMPLD}" ]]; then
  rm -rf "${CMPLD}"
fi

mkdir -p ${SRC}
mkdir -p ${CMPLD}

export PATH=${SRC}/bin:$PATH
export CC=clang && export PKG_CONFIG_PATH="${SRC}/lib/pkgconfig"
export MACOSX_DEPLOYMENT_TARGET=11.0

if [[ "$(uname -m)" == "arm64" ]]; then
  export ARCH=arm64
else
  export ARCH=x86_64
fi

export LDFLAGS=${LDFLAGS:-}
export CFLAGS=${CFLAGS:-}

function ensure_package () {
  if [[ "$ARCH" == "arm64" ]]; then
    if [[ ! -e "/opt/homebrew/opt/$1" ]]; then
      echo "Installing $1 using Homebrew"
      brew install "$1"

      export LDFLAGS="-L/opt/homebrew/opt/$1/lib ${LDFLAGS}"
      export CFLAGS="-I/opt/homebrew/opt/$1/include ${CFLAGS}"
      export PKG_CONFIG_PATH="$PKG_CONFIG_PATH:/opt/homebrew/opt/$1/lib/pkgconfig"
    fi
  else
    if [[ ! -e "/usr/local/opt/$1" ]]; then
      echo "Installing $1 using Homebrew"
      brew install "$1"
      export LDFLAGS="-L/usr/local/opt/$1/lib ${LDFLAGS}"
      export CFLAGS="-I/usr/local/opt/$1/include ${CFLAGS}"
      export PKG_CONFIG_PATH="$PKG_CONFIG_PATH:/usr/local/opt/$1/lib/pkgconfig"
    fi
  fi
}

ensure_package pkgconfig
ensure_package libtool
ensure_package glib

if ! command -v autoreconf &> /dev/null; then
  brew install autoconf
fi
if ! command -v automake &> /dev/null; then
  brew install automake
fi
if ! command -v cmake &> /dev/null; then
  brew install cmake
fi

echo "Cloning required git repositories"
git clone --depth 1 -b master https://code.videolan.org/videolan/x264.git $CMPLD/x264 &
git clone --depth 1 -b origin https://github.com/rbrito/lame.git $CMPLD/lame &
git clone --depth 1 -b main https://github.com/webmproject/libvpx $CMPLD/libvpx &
git clone --depth 1 -b master https://github.com/FFmpeg/FFmpeg $CMPLD/ffmpeg &
git clone --depth 1 -b v2.0.1 https://aomedia.googlesource.com/aom.git $CMPLD/aom &
wait

curl -Ls -o - https://bitbucket.org/multicoreware/x265_git/downloads/x265_3.3.tar.gz | tar zxf - -C $CMPLD/ &
# statically linking glibc is discouraged
# echo "Downloading: glib (2.66.2)"
# curl -Ls -o - https://download.gnome.org/sources/glib/2.66/glib-2.66.2.tar.xz | tar Jxf - -C $CMPLD/
# curl -o "$CMPLD/glib-2.66.2/hardcoded-patchs.diff" https://raw.githubusercontent.com/Homebrew/formula-patches/6164294a75541c278f3863b111791376caa3ad26/glib/hardcoded-paths.diff
echo "Downloading: fribidi (1.0.10)"
{(curl -Ls -o - https://github.com/fribidi/fribidi/releases/download/v1.0.10/fribidi-1.0.10.tar.xz | tar Jxf - -C $CMPLD/) &};
echo "Downloading: vid.stab (1.1.0)"
curl -Ls -o - https://github.com/georgmartius/vid.stab/archive/v1.1.0.tar.gz | tar zxf - -C $CMPLD/
curl -s -o "$CMPLD/vid.stab-1.1.0/fix_cmake_quoting.patch" https://raw.githubusercontent.com/Homebrew/formula-patches/5bf1a0e0cfe666ee410305cece9c9c755641bfdf/libvidstab/fix_cmake_quoting.patch
echo "Downloading: snappy (1.1.8)"
{(curl -Ls -o - https://github.com/google/snappy/archive/1.1.8.tar.gz | tar zxf - -C $CMPLD/) &};
echo "Downloading: enca (1.19)"
{(curl -Ls -o - https://dl.cihar.com/enca/enca-1.19.tar.gz | tar zxf - -C $CMPLD/) &};
echo "Downloading: libiconv (1.16)"
{(curl -Ls -o - https://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.16.tar.gz | tar zxf - -C $CMPLD/) &};
echo "Downloading: zlib (1.2.11)"
{(curl -Ls -o - https://zlib.net/fossils/zlib-1.2.11.tar.gz | tar zxf - -C $CMPLD/) &};
echo "Downloading: libtheora (1.1.1)"
{(curl -Ls -o - http://downloads.xiph.org/releases/theora/libtheora-1.1.1.tar.bz2 | tar xf - -C $CMPLD/) &};
echo "Downloading: expat (2.2.10)"
{(curl -Ls -o - https://github.com/libexpat/libexpat/releases/download/R_2_2_10/expat-2.2.10.tar.gz | tar zxf - -C $CMPLD/) &};
echo "Downloading: freetype (2.10.4)"
{(curl -Ls -o - https://download.savannah.gnu.org/releases/freetype/freetype-2.10.4.tar.gz | tar zxf - -C $CMPLD/) &};
echo "Downloading: gettext (0.21)"
{(curl -Ls -o - https://ftp.gnu.org/gnu/gettext/gettext-0.21.tar.xz | tar Jxf - -C $CMPLD/) &};
echo "Downloading: fontconfig (2.13.93)"
{(curl -Ls -o - https://www.freedesktop.org/software/fontconfig/release/fontconfig-2.13.93.tar.gz | tar zxf - -C $CMPLD/) &};
echo "Downloading: libass (0.15.0)"
{(curl -Ls -o - https://github.com/libass/libass/releases/download/0.15.0/libass-0.15.0.tar.gz | tar zxf - -C $CMPLD/) &};
echo "Downloading: yasm (1.3.0)"
{(curl -Ls -o - http://www.tortall.net/projects/yasm/releases/yasm-1.3.0.tar.gz | tar zxf - -C $CMPLD/) &};
echo "Downloading: pkg-config (0.29.2)"
{(curl -Ls -o - https://pkg-config.freedesktop.org/releases/pkg-config-0.29.2.tar.gz | tar zxf - -C $CMPLD/) &};
echo "Downloading: nasm (2.15.05)"
{(curl -Ls -o - https://www.nasm.us/pub/nasm/releasebuilds/2.15.05/nasm-2.15.05.tar.gz | tar zxf - -C $CMPLD/) &};
echo "Downloading: libvorbis (1.3.7)"
{(curl -Ls -o - https://ftp.osuosl.org/pub/xiph/releases/vorbis/libvorbis-1.3.7.tar.gz | tar zxf - -C $CMPLD/) &};
echo "Downloading: libopus (1.3.1)"
{(curl -Ls -o - https://archive.mozilla.org/pub/opus/opus-1.3.1.tar.gz | tar zxf - -C $CMPLD/) &};
echo "Downloading: harfbuzz (2.7.2)"
{(curl -Ls -o - https://github.com/harfbuzz/harfbuzz/releases/download/2.7.2/harfbuzz-2.7.2.tar.xz | tar Jxf - -C $CMPLD/) &};
echo "Downloading: libogg (1.3.4)"
curl -Ls -o - https://ftp.osuosl.org/pub/xiph/releases/ogg/libogg-1.3.4.tar.gz | tar zxf - -C $CMPLD/
curl -s -o "$CMPLD/libogg-1.3.4/fix_unsigned_typedefs.patch" "https://github.com/xiph/ogg/commit/c8fca6b4a02d695b1ceea39b330d4406001c03ed.patch?full_index=1"

wait

function build_fribidi () {
  if [[ ! -e "${SRC}/lib/pkgconfig/fribidi.pc" ]]; then
    echo '♻️ ' Start compiling FRIBIDI
    cd ${CMPLD}
    cd fribidi-1.0.10
    ./configure --prefix=${SRC} --disable-debug --disable-dependency-tracking --disable-silent-rules --disable-shared --enable-static
    make -j ${NUM_PARALLEL_BUILDS}
    make install
  fi
}

function build_yasm () {
  if [[ ! -e "${SRC}/lib/libyasm.a" ]]; then
    echo '♻️ ' Start compiling YASM
    cd ${CMPLD}
    cd yasm-1.3.0
    ./configure --prefix=${SRC}
    make -j ${NUM_PARALLEL_BUILDS}
    make install
  fi
}

function build_aom () {
  if [[ ! -e "${SRC}/lib/pkgconfig/aom.pc" ]]; then
    echo '♻️ ' Start compiling AOM
    cd ${CMPLD}
    cd aom
    mkdir aom_build
    cd aom_build

    AOM_CMAKE_PARAMS="-DENABLE_DOCS=off -DENABLE_EXAMPLES=off -DENABLE_TESTDATA=off -DENABLE_TESTS=off -DENABLE_TOOLS=off -DCMAKE_INSTALL_PREFIX:PATH=${SRC} -DLIBTYPE=STATIC"
    if [[ "$ARCH" == "arm64" ]]; then
      AOM_CMAKE_PARAMS="$AOM_CMAKE_PARAMS -DCONFIG_RUNTIME_CPU_DETECT=0"
    fi
    cmake ${CMPLD}/aom $AOM_CMAKE_PARAMS
    make -j ${NUM_PARALLEL_BUILDS}
    make install
  fi
}

function build_nasm () {
  if [[ ! -e "${SRC}/bin/nasm" ]]; then
    echo '♻️ ' Start compiling NASM
    #
    # compile NASM
    #
    cd ${CMPLD}
    cd nasm-2.15.05
    ./configure --prefix=${SRC}
    make -j ${NUM_PARALLEL_BUILDS}
    make install
  fi
}

function build_pkgconfig () {
  if [[ ! -e "${SRC}/bin/pkg-config" ]]; then
    echo '♻️ ' Start compiling pkg-config
    cd ${CMPLD}
    cd pkg-config-0.29.2
    export LDFLAGS="-framework Foundation -framework Cocoa"
    ./configure --prefix=${SRC} --with-pc-path=${SRC}/lib/pkgconfig --with-internal-glib --disable-shared --enable-static
    make -j ${NUM_PARALLEL_BUILDS}
    make install
    unset LDFLAGS
  fi
}

function build_zlib () {
  if [[ ! -e "${SRC}/lib/pkgconfig/zlib.pc" ]]; then
    echo '♻️ ' Start compiling ZLIB
    cd ${CMPLD}
    cd zlib-1.2.11
    ./configure --prefix=${SRC}
    make -j ${NUM_PARALLEL_BUILDS}
    make install
    rm ${SRC}/lib/libz.so* || true
    rm ${SRC}/lib/libz.* || true
  fi
}

function build_lame () {
  if [[ ! -e "${SRC}/lib/libmp3lame.a" ]]; then
    cd ${CMPLD}
    cd lame
    ./configure --prefix=${SRC} --disable-shared --enable-static
    make -j ${NUM_PARALLEL_BUILDS}
    make install
  fi
}

function build_x264 () {
  if [[ ! -e "${SRC}/lib/pkgconfig/x264.pc" ]]; then
    echo '♻️ ' Start compiling X264
    cd ${CMPLD}
    cd x264
    ./configure --prefix=${SRC} --disable-shared --enable-static --enable-pic
    make -j ${NUM_PARALLEL_BUILDS}
    make install
    make install-lib-static
  fi
}

function build_x265 () {
  if [[ ! -e "${SRC}/lib/pkgconfig/x265.pc" ]]; then
    echo '♻️ ' Start compiling X265
    rm -f ${SRC}/include/x265*.h 2>/dev/null
    rm -f ${SRC}/lib/libx265.a 2>/dev/null

    echo '♻️ ' X265 12bit
    cd ${CMPLD}
    cd x265_3.3/source
    cmake -DCMAKE_INSTALL_PREFIX:PATH=${SRC} -DHIGH_BIT_DEPTH=ON -DMAIN12=ON -DENABLE_SHARED=NO -DEXPORT_C_API=NO -DENABLE_CLI=OFF .
    make -j ${NUM_PARALLEL_BUILDS}
    mv libx265.a libx265_main12.a
    make clean-generated
    rm CMakeCache.txt

    echo '♻️ ' X265 10bit
    cd ${CMPLD}
    cd x265_3.3/source
    cmake -DCMAKE_INSTALL_PREFIX:PATH=${SRC} -DMAIN10=ON -DHIGH_BIT_DEPTH=ON -DENABLE_SHARED=NO -DEXPORT_C_API=NO -DENABLE_CLI=OFF .
    make clean
    make -j ${NUM_PARALLEL_BUILDS}
    mv libx265.a libx265_main10.a
    make clean-generated && rm CMakeCache.txt

    echo '♻️ ' X265 full
    cd ${CMPLD}
    cd x265_3.3/source
    cmake -DCMAKE_INSTALL_PREFIX:PATH=${SRC} -DEXTRA_LIB="x265_main10.a;x265_main12.a" -DEXTRA_LINK_FLAGS=-L. -DLINKED_12BIT=ON -DLINKED_10BIT=ON -DENABLE_SHARED=OFF -DENABLE_CLI=OFF .
    make clean
    make -j ${NUM_PARALLEL_BUILDS}

    mv libx265.a libx265_main.a
    libtool -static -o libx265.a libx265_main.a libx265_main10.a libx265_main12.a 2>/dev/null
    make install
  fi
}

function build_vpx () {
  if [[ ! -e "${SRC}/lib/pkgconfig/vpx.pc" ]]; then
    echo '♻️ ' Start compiling VPX
    cd ${CMPLD}
    cd libvpx
    ./configure --prefix=${SRC} --enable-vp8 --enable-postproc --enable-vp9-postproc --enable-vp9-highbitdepth --disable-examples --disable-docs --enable-multi-res-encoding --disable-unit-tests --enable-pic --disable-shared
    make -j ${NUM_PARALLEL_BUILDS}
    make install
  fi
}

function build_expat () {
  if [[ ! -e "${SRC}/lib/pkgconfig/expat.pc" ]]; then
    echo '♻️ ' Start compiling EXPAT
    cd ${CMPLD}
    cd expat-2.2.10
    ./configure --prefix=${SRC} --disable-shared --enable-static
    make -j ${NUM_PARALLEL_BUILDS}
    make install
  fi
}

function build_libiconv () {
  if [[ ! -e "${SRC}/lib/libiconv.a" ]]; then
    echo '♻️ ' Start compiling LIBICONV
    cd ${CMPLD}
    cd libiconv-1.16
    ./configure --prefix=${SRC} --disable-shared --enable-static
    make -j ${NUM_PARALLEL_BUILDS}
    make install
  fi
}

function build_enca () {
  if [[ ! -d "${SRC}/libexec/enca" ]]; then
    echo '♻️ ' Start compiling ENCA
    cd ${CMPLD}
    cd enca-1.19
    ./configure --prefix=${SRC} --disable-dependency-tracking --disable-shared --enable-static
    make -j ${NUM_PARALLEL_BUILDS}
    make install
  fi
}

function build_freetype () {
  if [[ ! -e "${SRC}/lib/pkgconfig/freetype2.pc" ]]; then
    echo '♻️ ' Start compiling FREETYPE
    cd ${CMPLD}
    cd freetype-2.10.4
    ./configure --prefix=${SRC} --disable-shared --enable-static
    make -j ${NUM_PARALLEL_BUILDS}
    make install
  fi
}

function build_gettext () {
  if [[ ! -e "${SRC}/lib/pkgconfig/gettext.pc" ]]; then
    echo '♻️ ' Start compiling gettext
    cd ${CMPLD}
    cd gettext-0.21
    ./configure --prefix=${SRC} --disable-dependency-tracking --disable-silent-rules --disable-debug --disable-shared --enable-static \
                --with-included-gettext --with-included-glib --with-includedlibcroco --with-included-libunistring --with-emacs \
                --disable-java --disable-csharp --without-git --without-cvs --without-xz
    make -j ${NUM_PARALLEL_BUILDS}
    make install
  fi
}

function build_fontconfig () {
  if [[ ! -e "${SRC}/lib/pkgconfig/fontconfig.pc" ]]; then
    echo '♻️ ' Start compiling FONTCONFIG
    cd ${CMPLD}
    cd fontconfig-2.13.93
    ./configure --prefix=${SRC} --enable-iconv --disable-libxml2 --disable-shared --enable-static --disable-docs
    make -j ${NUM_PARALLEL_BUILDS}
    make install
  fi
}

function build_harfbuzz () {
  if [[ ! -e "${SRC}/lib/pkgconfig/harfbuzz.pc" ]]; then
    echo '♻️ ' Start compiling harfbuzz
    cd ${CMPLD}
    cd harfbuzz-2.7.2
    ./configure --prefix=${SRC} --disable-shared --enable-static
    make -j ${NUM_PARALLEL_BUILDS}
    make install
  fi
}

function build_ass () {
  if [[ ! -e "${SRC}/lib/pkgconfig/libass.pc" ]]; then
    cd ${CMPLD}
    cd libass-0.15.0
    autoreconf -i
    ./configure --prefix=${SRC} --disable-dependency-tracking --disable-shread --enable-static
    make -j ${NUM_PARALLEL_BUILDS}
    make install
  fi
}

function build_opus () {
  if [[ ! -e "${SRC}/lib/pkgconfig/opus.pc" ]]; then
    echo '♻️ ' Start compiling OPUS
    cd ${CMPLD}
    cd opus-1.3.1
    ./configure --prefix=${SRC} --disable-shared --enable-static
    make -j ${NUM_PARALLEL_BUILDS}
    make install
  fi
}

function build_ogg () {
  if [[ ! -e "${SRC}/lib/pkgconfig/ogg.pc" ]]; then
    echo '♻️ ' Start compiling LIBOGG
    cd ${CMPLD}
    cd libogg-1.3.4
    patch -p1 < ./fix_unsigned_typedefs.patch
    ./configure --prefix=${SRC} --disable-shared --enable-static
    make -j ${NUM_PARALLEL_BUILDS}
    make install
  fi
}

function build_vorbis () {
  if [[ ! -e "${SRC}/lib/pkgconfig/vorbis.pc" ]]; then
    echo '♻️ ' Start compiling LIBVORBIS
    cd ${CMPLD}
    cd libvorbis-1.3.7
    ./configure --prefix=${SRC} --with-ogg-libraries=${SRC}/lib --with-ogg-includes=${SRC}/include/ --enable-static --disable-shared --build=x86_64
    make -j ${NUM_PARALLEL_BUILDS}
    make install
  fi
}

function build_theora () {
  if [[ ! -e "${SRC}/lib/pkgconfig/theora.pc" ]]; then
    echo '♻️ ' Start compiling THEORA
    cd ${CMPLD}
    cd libtheora-1.1.1
    ./configure --prefix=${SRC} --disable-asm --with-ogg-libraries=${SRC}/lib --with-ogg-includes=${SRC}/include/ --with-vorbis-libraries=${SRC}/lib --with-vorbis-includes=${SRC}/include/ --enable-static --disable-shared
    make -j ${NUM_PARALLEL_BUILDS}
    make install
  fi
}

function build_vidstab () {
  if [[ ! -e "${SRC}/lib/pkgconfig/vidstab.pc" ]]; then
    echo '♻️ ' Start compiling Vid-stab
    cd ${CMPLD}
    cd vid.stab-1.1.0
    patch -p1 < fix_cmake_quoting.patch
    cmake . -DCMAKE_INSTALL_PREFIX:PATH=${SRC} -DLIBTYPE=STATIC -DBUILD_SHARED_LIBS=OFF -DUSE_OMP=OFF -DENABLE_SHARED=off
    make -j ${NUM_PARALLEL_BUILDS}
    make install
  fi
}

function build_snappy () {
  if [[ ! -e "${SRC}/lib/libsnappy.a" ]]; then
    echo '♻️ ' Start compiling Snappy
    cd ${CMPLD}
    cd snappy-1.1.8
    cmake . -DCMAKE_INSTALL_PREFIX:PATH=${SRC} -DLIBTYPE=STATIC -DENABLE_SHARED=off
    make -j ${NUM_PARALLEL_BUILDS}
    make install
  fi
}

function build_ffmpeg () {
  echo '♻️ ' Start compiling FFMPEG
  cd ${CMPLD}
  cd ffmpeg
  export LDFLAGS="-L${SRC}/lib ${LDFLAGS:-}"
  export CFLAGS="-I${SRC}/include ${CFLAGS:-}"
  export LDFLAGS="$LDFLAGS -lexpat -lenca -lfribidi -liconv -lstdc++ -lfreetype -framework CoreText -framework VideoToolbox"
  ./configure --prefix=${SRC} --extra-cflags="-fno-stack-check" --arch=${ARCH} --cc=/usr/bin/clang \
              --enable-fontconfig --enable-gpl --enable-libopus --enable-libtheora --enable-libvorbis \
              --enable-libmp3lame --enable-libass --enable-libfreetype --enable-libx264 --enable-libx265 --enable-libvpx \
              --enable-libaom --enable-libvidstab --enable-libsnappy --enable-version3 --pkg-config-flags=--static \
              --disable-ffplay --enable-postproc --enable-nonfree --enable-runtime-cpudetect
  echo "build start"
  start_time="$(date -u +%s)"
  make -j ${NUM_PARALLEL_BUILDS}
  end_time="$(date -u +%s)"
  elapsed="$(($end_time-$start_time))"
  make install
  echo "[FFmpeg] $elapsed seconds elapsed for build"
}

total_start_time="$(date -u +%s)"
build_fribidi
build_yasm
build_aom
build_nasm
build_pkgconfig
build_zlib
build_lame
build_x264
build_x265
build_vpx
build_expat
build_libiconv
build_enca
build_freetype
if [[ "$ARCH" == "arm64" ]]; then
  build_gettext
fi
build_fontconfig
build_harfbuzz
build_ass
build_opus
build_ogg
build_vorbis
build_theora
build_vidstab
build_snappy
build_ffmpeg
total_end_time="$(date -u +%s)"
total_elapsed="$(($total_end_time-$total_start_time))"
echo "Total $total_elapsed seconds elapsed for build"
