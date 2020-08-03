#!/usr/bin/env bash

set -e

export APPLE_VER=12
OSXCROSS_ROOT=/opt/osxcross/target/bin
export PATH=$OSXCROSS_ROOT:$PATH
export OSX_ARCH=x86_64
export OSX_CC=o64-gcc
export OSX_CXX=o64-g++
export CC=${OSX_CC}
export CXX=${OSX_CXX}
export AR=${OSXCROSS_ROOT}/$OSX_ARCH-apple-darwin${APPLE_VER}-ar
export RANLIB=${OSXCROSS_ROOT}/$OSX_ARCH-apple-darwin${APPLE_VER}-ranlib
export compiler=$OSX_ARCH-apple-darwin${APPLE_VER}

#only build statlib for macos, no static support:
#see https://stackoverflow.com/questions/5259249/creating-static-mac-os-x-c-build
bc=megadepth_statlib

if [[ ! -s libdeflate_macos ]] ; then
    ./get_libdeflate.sh $compiler macos
    ln -fs libdeflate_macos libdeflate
fi

export CFLAGS="-I../libdeflate"
export LDFLAGS="-L../libdeflate -ldeflate"
if [[ ! -e htslib_macos/libhts.a ]] ; then
    ./get_htslib.sh $compiler macos
    ln -fs htslib_macos htslib
fi

if [[ ! -s libBigWig_macos ]] ; then
    ./get_libBigWig.sh macos
    ln -fs libBigWig_macos libBigWig
    pushd libBigWig
    make clean
    make -f Makefile.fpic lib-static
    popd
fi

export CFLAGS=
export LDFLAGS=

set -x

export LD_LIBRARY_PATH=./htslib:./libBigWig:$LD_LIBRARY_PATH

DR=build-release-temp
mkdir -p ${DR}
pushd ${DR}
#CC=${OSX_CC} CXX=${OSX_CXX} cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_AR=/opt/osxcross/target/bin/$OSX_ARCH-apple-darwin${APPLE_VER}-ar -DCMAKE_RANLIB=/opt/osxcross/target/bin/$OSX_ARCH-apple-darwin${APPLE_VER}-ranlib -D CMAKE_C_COMPILER=${OSX_CC} -D CMAKE_CXX_COMPILER=${OSX_CXX} ..
#CC=${OSX_CC} CXX=${OSX_CXX} AR=/opt/osxcross/target/bin/$OSX_ARCH-apple-darwin${APPLE_VER}-ar RANLIB=/opt/osxcross/target/bin/$OSX_ARCH-apple-darwin${APPLE_VER}-ranlib make ${bc}
cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_AR=${AR} -DCMAKE_RANLIB=${RANLIB} -D CMAKE_C_COMPILER=${OSX_CC} -D CMAKE_CXX_COMPILER=${OSX_CXX} ..
make ${bc}
popd
cp ${DR}/${bc} ./
ln -fs ./$bc megadepth
./megadepth --version
rm -rf ${DR}

DR=build-debug-temp
mkdir -p ${DR}
pushd ${DR}
cmake -DCMAKE_BUILD_TYPE=Debug -DCMAKE_AR=${AR} -DCMAKE_RANLIB=${RANLIB} -D CMAKE_C_COMPILER=${OSX_CC} -D CMAKE_CXX_COMPILER=${OSX_CXX} ..
make ${bc}
popd
cp ${DR}/${bc} ./${bc}_debug
ln -fs ./${bc}_debug megadepth_debug
./megadepth_debug --version
rm -rf ${DR}
