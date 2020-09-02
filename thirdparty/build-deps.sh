#!/bin/sh

#
# Build script for libopenshot dependencies.
# Set MANYLINUX=1 in environment before running, to install build tools
# into manylinux2014 CentOS 7 container image
# 
# Script heavily lifted from pyav-ffmpeg, much indebted
# See https://github.com/PyAV-Org/pyav-ffmpeg for info

set -xe

if [ -z "$1" ]; then
#    echo "Usage: $0 <prefix>"
#    exit 1
    destdir=`pwd`/libs
else
    destdir=$1
fi

libopenshot_version=0.2.5
ffmpeg_version=4.2.2

builddir=`pwd`/build
sourcedir=`pwd`/source


build() {
    path=$builddir/$1
    shift
    configure_args=$*
    cd $path
    ./configure $configure_args --prefix=$destdir
    make -j
    make install
    cd $builddir
}

extract() {
    path=$builddir/$1
    url=$2
    tarball=$sourcedir/`echo $url | sed -e 's/.*\///'`

    if [ -e "$path" ]; then
        echo "\n$1 already built, skipping. 'rm -r $builddir/$1' to rebuild\n"
        return
    fi

    if [ -z "$3" ]; then
        strip_components=1
    else
        strip_components=$3
    fi

    if [ ! -e $tarball ]; then
        curl -L -o $tarball $url
    fi

    mkdir $path
    tar xf $tarball -C $path --strip-components $strip_components
}

# Only needed when running in the manylinux docker image
do_manylinux_prep() {

    # needed for fontconfig
    yum -y install libuuid-devel

    #### BUILD TOOLS ####

    # Enable devtoolset-9 (GCC 9)
    yum install devtoolset-9-gcc devtoolset-9-gcc-c++
    source /opt/rh/devtoolset-9/enable

    # install cmake and meson
    pip install cmake meson

    # clear out build tree completely
    for d in $builddir $destdir; do
        if [ -e $d ]; then
            rm -rf $d
        fi
    done
}

if [ ! -z "$MANYLINUX" ]; then
  do_manylinux_prep
fi

cmake_args="-DCMAKE_PREFIX_PATH=$destdir -DCMAKE_INSTALL_LIBDIR=lib -DCMAKE_INSTALL_PREFIX=$destdir"
outputdir=`pwd`/output
if [ "`uname`" = "Linux" ]; then
    outputfile=$outputdir/libopenshot-manylinux_$(uname -m).tar.gz
elif [ "`uname`" = "Darwin" ]; then
    outputfile=$outputdir/libopenshot-macosx_$(uname -m).tar.gz
    cmake_args="$cmake_args -DCMAKE_INSTALL_NAME_DIR=$destdir/lib"
else
    echo "Unknown platform"
    exit 1
fi

mkdir -p $outputdir
if [ ! -e $outputfile ]; then
    mkdir $builddir
    mkdir -p $sourcedir
    cd $builddir

    export CPPFLAGS="-I$destdir/include $CPPFLAGS"
    export LDFLAGS="-L$destdir/lib $LDFLAGS"
    export PATH=$destdir/bin:$PATH
    export PKG_CONFIG_PATH=$destdir/lib/pkgconfig

    #### LIBRARIES ###
    
    # build libasound
    extract alsa alsa-libs-1.1.8.tar.xz
    build alsa
    
    # build xz
    extract xz https://tukaani.org/xz/xz-5.2.5.tar.bz2
    build xz
    
    # build zlib
    extract zlib https://www.zlib.net/zlib-1.2.11.tar.gz
    build zlib
    
    # build OpenShotAudio
    extract OpenShotAudio https://github.com/ferdnyc/libopenshot-audio/archive/v0.2.1-pre0.1.tar.gz
    cmake -B OpenShotAudio/build -S OpenShotAudio $cmake_args -DBUILD_SHARED_LIBS=1 -DWITH_RPATH=1
    cmake --build OpenShotAudio/build
    cmake --install OpenShotAudio/build
    
    # build jsoncpp
    extract jsoncpp https://github.com/open-source-parsers/jsoncpp/archive/1.9.3.tar.gz
    cmake -B jsoncpp/build -S jsoncpp $cmake_args -DBUILD_SHARED_LIBS=1
    cmake --build jsoncpp/build
    cmake --install jsoncpp/build
    
    # build zeromq
    extract zeromq https://github.com/zeromq/libzmq/releases/download/v4.3.2/zeromq-4.3.2.tar.gz
    cmake -B zeromq/build -S zeromq $cmake_args -DBUILD_SHARED_LIBS=1
    cmake --build zeromq/build
    cmake --install zeromq/build

    # build cppzmq (header-only)
    extract cppzmq https://github.com/zeromq/cppzmq/archive/v4.6.0.tar.gz
    cmake -B cppzmq/build -S cppzmq $cmake_args -DBUILD_SHARED_LIBS=1
    cmake --build cppzmq/build
    cmake --install cppzmq/build
    
    # build gmp
    extract gmp https://gmplib.org/download/gmp/gmp-6.2.0.tar.xz
    build gmp
    
    # build png (requires zlib)
    extract png http://deb.debian.org/debian/pool/main/libp/libpng1.6/libpng1.6_1.6.37.orig.tar.gz
    build png
    
    # build xml2 (requires xz and zlib)
    extract xml2 ftp://xmlsoft.org/libxml2/libxml2-sources-2.9.10.tar.gz
    build xml2 --without-python
    
    # build unistring
    extract unistring https://ftp.gnu.org/gnu/libunistring/libunistring-0.9.10.tar.gz
    build unistring

    # build gettext (requires unistring and xml2)
    extract gettext https://ftp.gnu.org/pub/gnu/gettext/gettext-0.21.tar.gz
    build gettext --disable-java --without-emacs

    # build freetype (requires png)
    extract freetype https://download.savannah.gnu.org/releases/freetype/freetype-2.10.1.tar.gz
    build freetype
    
    # build fontconfig (requires freetype and libxml2)
    extract fontconfig https://www.freedesktop.org/software/fontconfig/release/fontconfig-2.13.1.tar.bz2
    build fontconfig --enable-libxml2
    
    # build fribidi
    extract fribidi https://github.com/fribidi/fribidi/releases/download/v1.0.9/fribidi-1.0.9.tar.xz
    build fribidi
    
    # build nettle (requires gmp)
    extract nettle https://ftp.gnu.org/gnu/nettle/nettle-3.6.tar.gz
    build nettle --libdir=$destdir/lib

    # build gnutls (requires nettle and unistring)
    extract gnutls https://www.gnupg.org/ftp/gcrypt/gnutls/v3.6/gnutls-3.6.14.tar.xz
    build gnutls --disable-doc --disable-tools --disable-guile --with-included-libtasn1 --without-p11-kit

    ### CODECS ###

    # build aom
    extract aom https://aomedia.googlesource.com/aom/+archive/a6091ebb8a7da245373e56a005f2bb95be064e03.tar.gz 0
    mkdir aom/tmp
    cd aom/tmp
    cmake .. $cmake_args -DBUILD_SHARED_LIBS=1
    make -j
    make install
    cd $builddir

    # build ass (requires freetype and fribidi)
    extract ass https://github.com/libass/libass/releases/download/0.14.0/libass-0.14.0.tar.gz
    build ass

    # build bluray (requires fontconfig)
    extract bluray https://download.videolan.org/pub/videolan/libbluray/1.1.2/libbluray-1.1.2.tar.bz2
    build bluray --disable-bdjava-jar

    # build dav1d (requires meson, nasm and ninja)
    extract dav1d https://code.videolan.org/videolan/dav1d/-/archive/master/dav1d-master.tar.bz2
    mkdir dav1d/build
    cd dav1d/build
    meson .. --libdir=lib --prefix=$destdir
    ninja
    ninja install
    cd $builddir

    # build lame
    extract lame http://deb.debian.org/debian/pool/main/l/lame/lame_3.100.orig.tar.gz
    sed -i.bak '/^lame_init_old$/d' lame/include/libmp3lame.sym
    build lame

    # build ogg
    extract ogg http://downloads.xiph.org/releases/ogg/libogg-1.3.4.tar.gz
    cat <<EOF | patch -p0
--- ogg/include/ogg/os_types.h
+++ ogg/include/ogg/os_types.h
@@ -72,11 +72,11 @@

 #  include <sys/types.h>
    typedef int16_t ogg_int16_t;
-   typedef uint16_t ogg_uint16_t;
+   typedef u_int16_t ogg_uint16_t;
    typedef int32_t ogg_int32_t;
-   typedef uint32_t ogg_uint32_t;
+   typedef u_int32_t ogg_uint32_t;
    typedef int64_t ogg_int64_t;
-   typedef uint64_t ogg_uint64_t;
+   typedef u_int64_t ogg_uint64_t;

 #elif defined(__HAIKU__)

EOF
    build ogg

    # build opencore-amr
    extract opencore-amr http://deb.debian.org/debian/pool/main/o/opencore-amr/opencore-amr_0.1.5.orig.tar.gz
    build opencore-amr

    # build openjpeg
    extract openjpeg https://github.com/uclouvain/openjpeg/archive/v2.3.1.tar.gz
    cd openjpeg
    cmake . $cmake_args
    make -j
    make install
    cd $builddir

    # build opus
    extract opus https://archive.mozilla.org/pub/opus/opus-1.3.1.tar.gz
    build opus

    # build speex
    extract speex http://downloads.xiph.org/releases/speex/speex-1.2.0.tar.gz
    build speex

    # build twolame
    extract twolame http://deb.debian.org/debian/pool/main/t/twolame/twolame_0.4.0.orig.tar.gz
    build twolame

    # build vorbis (requires ogg)
    extract vorbis http://downloads.xiph.org/releases/vorbis/libvorbis-1.3.6.tar.gz
    build vorbis

    # build theora (requires vorbis)
    extract theora http://downloads.xiph.org/releases/theora/libtheora-1.1.1.tar.gz
    build theora --disable-examples --disable-spec

    # build wavpack
    extract wavpack http://www.wavpack.com/wavpack-5.3.0.tar.bz2
    build wavpack
    
    # build x264
    extract x264 https://code.videolan.org/videolan/x264/-/archive/master/x264-master.tar.bz2
    build x264 --enable-shared
    
    # build x265
    extract x265 http://ftp.videolan.org/pub/videolan/x265/x265_3.2.1.tar.gz
    cd x265/build
    cmake ../source $cmake_args
    make -j
    make install
    cd $builddir
    
    # build xvid
    extract xvid https://downloads.xvid.com/downloads/xvidcore-1.3.7.tar.gz
    build xvid/build/generic

    # build ffmpeg
    extract ffmpeg https://ffmpeg.org/releases/ffmpeg-$ffmpeg_version.tar.gz
    build ffmpeg \
        --disable-doc \
        --disable-static \
        --enable-fontconfig \
        --enable-gmp \
        --enable-gnutls \
        --enable-gpl \
        --enable-libaom \
        --enable-libass \
        --enable-libbluray \
        --enable-libdav1d \
        --enable-libfreetype \
        --enable-libmp3lame \
        --enable-libopencore-amrnb \
        --enable-libopencore-amrwb \
        --enable-libopenjpeg \
        --enable-libopus \
        --enable-libspeex \
        --enable-libtheora \
        --enable-libtwolame \
        --enable-libvorbis \
        --enable-libwavpack \
        --enable-libx264 \
        --enable-libx265 \
        --enable-libxml2 \
        --enable-libxvid \
        --enable-lzma \
        --enable-shared \
        --enable-version3 \
        --enable-zlib

    if [ "`uname`" = "Darwin" ]; then
        otool -L $destdir/lib/*.dylib
    fi
    tar czvf $outputfile -C $destdir include lib
fi

