#!/bin/bash
set -exuo pipefail

echo '♻️ ' Create Ramdisk

if df | grep Ramdisk > /dev/null ; then tput bold ; echo ; echo ⏏ Eject Ramdisk ; tput sgr0 ; fi

if df | grep Ramdisk > /dev/null ; then diskutil eject Ramdisk ; sleep 1 ; fi

DISK_ID=$(hdid -nomount ram://8000000)

newfs_hfs -v tempdisk ${DISK_ID}

diskutil mount ${DISK_ID}

SRC="/Volumes/tempdisk/sw"

CMPLD="/Volumes/tempdisk/compile"

NUM_PARALLEL_BUILDS=$(sysctl -n hw.ncpu)

if [[ -e "${SRC}" ]]; then
  rm -rf "${SRC}"
fi

if [[ -e "${CMPLD}" ]]; then
  rm -rf "${CMPLD}"
fi

mkdir ${SRC}

mkdir ${CMPLD}

export PATH=${SRC}/bin:$PATH

export CC=clang && export PKG_CONFIG_PATH="${SRC}/lib/pkgconfig:/opt/homebrew/lib/pkgconfig"

export MACOSX_DEPLOYMENT_TARGET=11.0

if [[ "$(uname -m)" == "arm64" ]]; then
  export ARCH=arm64
else
  export ARCH=x86_64
fi

# set -o errexit

#
# ask user to copy all files to ramdisk
#

export LDFLAGS=${LDFLAGS:-}
export CFLAGS=${CFLAGS:-}

function ensure_package () {
 if [[ ! -e "/opt/homebrew/opt/$1" ]]; then
    echo "Installing $1 using Homebrew"
    brew install "$1"
  fi
}

ensure_package enca
ensure_package expat
ensure_package aom
ensure_package glib
# ensure_package fontconfig
ensure_package fribidi
ensure_package libvidstab

export LDFLAGS="-I/opt/homebrew/lib ${LDFLAGS}"
export CFLAGS="-I/opt/homebrew/include ${CFLAGS}"

git clone --depth 1 -b master https://code.videolan.org/videolan/x264.git $CMPLD/x264
# git clone --depth 1 -b master https://bitbucket.org/multicoreware/x265_git.git $CMPLD/x265
git clone --depth 1 -b origin https://github.com/rbrito/lame.git $CMPLD/lame
# git clone --depth 1 -b master https://github.com/fribidi/fribidi $CMPLD/fribidi
git clone --depth 1 -b master https://github.com/webmproject/libvpx $CMPLD/libvpx
git clone --depth 1 -b master https://github.com/georgmartius/vid.stab $CMPLD/vidstab-master
git clone --depth 1 -b master https://github.com/FFmpeg/FFmpeg $CMPLD/ffmpeg
curl -Ls -o - https://bitbucket.org/multicoreware/x265_git/downloads/x265_3.3.tar.gz | tar zxf - -C $CMPLD/
echo "Downloading: libiconv (1.16)"
curl -Ls -o - https://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.16.tar.gz | tar zxf - -C $CMPLD/
echo "Downloading: zlib (1.2.11)"
curl -Ls -o - https://zlib.net/zlib-1.2.11.tar.gz | tar zxf - -C $CMPLD/
echo "Downloading: libtheora (1.1.1)"
curl -Ls -o - http://downloads.xiph.org/releases/theora/libtheora-1.1.1.tar.bz2 | tar xf - -C $CMPLD/
echo "Downloading: expat (2.2.10)"
curl -Ls -o - https://github.com/libexpat/libexpat/releases/download/R_2_2_10/expat-2.2.10.tar.gz | tar zxf - -C $CMPLD/
echo "Downloading: freetype (2.10.4)"
curl -Ls -o - https://download.savannah.gnu.org/releases/freetype/freetype-2.10.4.tar.gz | tar zxf - -C $CMPLD/
echo "Downloading: fontconfig (2.13.93)"
curl -Ls -o - https://www.freedesktop.org/software/fontconfig/release/fontconfig-2.13.93.tar.gz | tar zxf - -C $CMPLD/
# echo "Downloading: libass (0.15.0)"
# curl -Ls -o - https://github.com/libass/libass/releases/download/0.15.0/libass-0.15.0.tar.gz | tar zxf - -C $CMPLD/
echo "Downloading: yasm (1.3.0)"
curl -Ls -o - http://www.tortall.net/projects/yasm/releases/yasm-1.3.0.tar.gz | tar zxf - -C $CMPLD/
echo "Downloading: pkg-config (0.29.2)"
curl -Ls -o - https://pkg-config.freedesktop.org/releases/pkg-config-0.29.2.tar.gz | tar zxf - -C $CMPLD/
echo "Downloading: nasm (2.15.05)"
curl -Ls -o - https://www.nasm.us/pub/nasm/releasebuilds/2.15.05/nasm-2.15.05.tar.gz | tar zxf - -C $CMPLD/
echo "Downloading: libvorbis (1.3.7)"
curl -Ls -o - https://downloads.xiph.org/releases/vorbis/libvorbis-1.3.7.tar.gz | tar zxf - -C $CMPLD/
echo "Downloading: libopus (1.3.1)"
curl -Ls -o - https://archive.mozilla.org/pub/opus/opus-1.3.1.tar.gz | tar zxf - -C $CMPLD/
echo "Downloading: libogg (1.3.4)"
curl -Ls -o - https://downloads.xiph.org/releases/ogg/libogg-1.3.4.tar.gz | tar zxf - -C $CMPLD/
# curl "Downloading: harfbuzz (2.7.2)"
# curl -Ls -o - https://github.com/harfbuzz/harfbuzz/releases/download/2.7.2/harfbuzz-2.7.2.tar.xz | tar Jxf - -C $CMPLD/


# echo '♻️ ' Start compiling harfbuzz

# cd ${CMPLD}

# cd harfbuzz-2.7.2

# ./configure --prefix=${SRC} --disable-shared --enable-static

# make -j ${NUM_PARALLEL_BUILDS}

# make install


echo '♻️ ' Start compiling FRIBIDI

#
# FRIBIDI
#

# cd ${CMPLD}

# cd fribidi

# ./configure --prefix=${SRC} --disable-shared --enable-static

# make -j ${NUM_PARALLEL_BUILDS}

# make install

echo '♻️ ' Start compiling YASM

#
# compile YASM
#

cd ${CMPLD}

cd yasm-1.3.0

./configure --prefix=${SRC}

make -j ${NUM_PARALLEL_BUILDS}

make install

echo '♻️ ' Start compiling NASM

#
# compile NASM
#

cd ${CMPLD}

cd nasm-2.15.05

./configure --prefix=${SRC}

make -j ${NUM_PARALLEL_BUILDS}

make install

echo '♻️ ' Start compiling PKG

#
# compile PKG
#

cd ${CMPLD}

cd pkg-config-0.29.2

export LDFLAGS="-framework Foundation -framework Cocoa"

./configure --prefix=${SRC} --with-pc-path=${SRC}/lib/pkgconfig --with-internal-glib --disable-shared --enable-static

make -j ${NUM_PARALLEL_BUILDS}

make install

unset LDFLAGS

echo '♻️ ' Start compiling ZLIB

#
# ZLIB
#

cd ${CMPLD}

cd zlib-1.2.11

./configure --prefix=${SRC}

make -j ${NUM_PARALLEL_BUILDS}

make install

rm ${SRC}/lib/libz.so* || true
rm ${SRC}/lib/libz.* || true

cd ${CMPLD}
cd lame
./configure --prefix=${SRC} --disable-shared --enable-static
make -j ${NUM_PARALLEL_BUILDS}
make install

echo '♻️ ' Start compiling X264

#
# x264
#

cd ${CMPLD}

cd x264

./configure --prefix=${SRC} --disable-shared --enable-static --enable-pic

make -j ${NUM_PARALLEL_BUILDS}

make install

make install-lib-static

echo '♻️ ' Start compiling X265

#
# x265
#

rm -f ${SRC}/include/x265*.h 2>/dev/null

rm -f ${SRC}/lib/libx265.a 2>/dev/null

echo '♻️ ' X265 12bit

cd ${CMPLD}

cd /Volumes/tempdisk/compile/x265_3.3/source

cmake -DCMAKE_INSTALL_PREFIX:PATH=${SRC} -DHIGH_BIT_DEPTH=ON -DMAIN12=ON -DENABLE_SHARED=NO -DEXPORT_C_API=NO -DENABLE_CLI=OFF .

make -j ${NUM_PARALLEL_BUILDS}

mv libx265.a libx265_main12.a

make clean-generated

rm CMakeCache.txt

echo '♻️ ' X265 10bit

cd ${CMPLD}

cd /Volumes/tempdisk/compile/x265_3.3/source

cmake -DCMAKE_INSTALL_PREFIX:PATH=${SRC} -DMAIN10=ON -DHIGH_BIT_DEPTH=ON -DENABLE_SHARED=NO -DEXPORT_C_API=NO -DENABLE_CLI=OFF .

make clean

make -j ${NUM_PARALLEL_BUILDS}

mv libx265.a libx265_main10.a

make clean-generated && rm CMakeCache.txt

echo '♻️ ' X265 full

cd ${CMPLD}

cd /Volumes/tempdisk/compile/x265_3.3/source

cmake -DCMAKE_INSTALL_PREFIX:PATH=${SRC} -DEXTRA_LIB="x265_main10.a;x265_main12.a" -DEXTRA_LINK_FLAGS=-L. -DLINKED_12BIT=ON -DLINKED_10BIT=ON -DENABLE_SHARED=OFF -DENABLE_CLI=OFF .

make clean

make -j ${NUM_PARALLEL_BUILDS}

mv libx265.a libx265_main.a

libtool -static -o libx265.a libx265_main.a libx265_main10.a libx265_main12.a 2>/dev/null

make install

echo '♻️ ' Start compiling VPX

#
# VPX
#

cd ${CMPLD}

cd libvpx

./configure --prefix=${SRC} --enable-vp8 --enable-postproc --enable-vp9-postproc --enable-vp9-highbitdepth --disable-examples --disable-docs --enable-multi-res-encoding --disable-unit-tests --enable-pic --disable-shared

make -j ${NUM_PARALLEL_BUILDS}

make install

# echo '♻️ ' Start compiling EXPAT

# #
# # EXPAT
# #

# cd ${CMPLD}

# cd expat-2.2.9

# ./configure --prefix=${SRC} --disable-shared --enable-static

# make -j ${NUM_PARALLEL_BUILDS}

# make install

echo '♻️ ' Start compiling LIBICONV

#
# libiconv
#

cd ${CMPLD}

cd libiconv-1.16

./configure --prefix=${SRC} --disable-shared --enable-static

make -j ${NUM_PARALLEL_BUILDS}

make install

echo '♻️ ' Start compiling FREETYPE

#
# FREETYPE
#

cd ${CMPLD}

cd freetype-2.10.4

./configure --prefix=${SRC} --disable-shared --enable-static

make -j ${NUM_PARALLEL_BUILDS}

make install

echo '♻️ ' Start compiling FONTCONFIG

# #
# # FONTCONFIG
# #

cd ${CMPLD}

cd fontconfig-2.13.93

./configure --prefix=${SRC} --enable-iconv --disable-libxml2 --disable-shared --enable-static --disable-docs

make -j ${NUM_PARALLEL_BUILDS}

make install


# echo '♻️ ' Start compiling LIBASS

# #
# # LIBASS
# #

# cd ${CMPLD}

# cd libass-0.15.0

# ./configure --prefix=${SRC} --disable-fontconfig --disable-shared --enable-static

# make -j ${NUM_PARALLEL_BUILDS}

# make install

echo '♻️ ' Start compiling OPUS

#
# OPUS
#

cd ${CMPLD}

cd opus-1.3.1

./configure --prefix=${SRC} --disable-shared --enable-static

make -j ${NUM_PARALLEL_BUILDS}

make install


echo '♻️ ' Start compiling LIBOGG

#
# LIBOGG
#

cd ${CMPLD}

cd libogg-1.3.4

./configure --prefix=${SRC} --disable-shared --enable-static

make -j ${NUM_PARALLEL_BUILDS}

make install

echo '♻️ ' Start compiling LIBVORBIS

#
# LIBVORBIS
#

cd ${CMPLD}

cd libvorbis-1.3.7

./configure --prefix=${SRC} --with-ogg-libraries=${SRC}/lib --with-ogg-includes=${SRC}/include/ --enable-static --disable-shared --build=x86_64

make -j ${NUM_PARALLEL_BUILDS}

make install

echo '♻️ ' Start compiling THEORA

#
# THEORA
#

cd ${CMPLD}

cd libtheora-1.1.1

./configure --prefix=${SRC} --disable-asm --with-ogg-libraries=${SRC}/lib --with-ogg-includes=${SRC}/include/ --with-vorbis-libraries=${SRC}/lib --with-vorbis-includes=${SRC}/include/ --enable-static --disable-shared

make -j ${NUM_PARALLEL_BUILDS}

make install

echo '♻️ ' Start compiling Vid-stab

#
# Vidstab
#

# cd ${CMPLD}

# cd vidstab-master

# cmake -DCMAKE_INSTALL_PREFIX:PATH=${SRC} -DLIBTYPE=STATIC -DBUILD_SHARED_LIBS=OFF -DUSE_OMP=OFF -DENABLE_SHARED=off .

# make -j ${NUM_PARALLEL_BUILDS}

# make install

echo '♻️ ' Start compiling FFMPEG

cd ${CMPLD}

cd ffmpeg

export LDFLAGS="-L${SRC}/lib ${LDFLAGS}"

export CFLAGS="-I${SRC}/include ${CFLAGS}"

export LDFLAGS="$LDFLAGS -lexpat -lenca -lfribidi -liconv -lstdc++ -lfreetype -framework CoreText -framework VideoToolbox"

./configure --prefix=${SRC} --extra-cflags="-fno-stack-check" --arch=${ARCH} --cc=/usr/bin/clang --enable-fontconfig --enable-gpl --enable-libopus --enable-libtheora --enable-libvorbis --enable-libmp3lame --enable-libfreetype --enable-libx264 --enable-libx265 --enable-libvpx --enable-libaom --enable-libvidstab --enable-version3 --pkg-config-flags=--static --disable-ffplay --enable-postproc --enable-nonfree --enable-runtime-cpudetect

# --enable-libaom
echo "build start"
start_time="$(date -u +%s)"
make -j ${NUM_PARALLEL_BUILDS}
end_time="$(date -u +%s)"

elapsed="$(($end_time-$start_time))"

make install

echo "Total of $elapsed seconds elapsed for build"
