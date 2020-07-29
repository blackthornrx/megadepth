#!/usr/bin/env bash

set -e
#build dynamic by default
build_type=$1
bc=`perl -e '$bt="'$build_type'"; if($bt=~/static/i) { print "megadepth_static"; } elsif($bt=~/statlib/i) { print "megadepth_statlib"; } else { print "megadepth_dynamic"; }'`

if [[ ! -s zlib ]] ; then
    ./get_zlib.sh
fi

if [[ ! -s libdeflate ]] ; then
    ./get_libdeflate.sh
fi

if [[ ! -s htslib ]] ; then
    export CPPFLAGS="-I../libdeflate -I../curl-7.71.1-win64-mingw/include -I../zlib-1.2.5-bin-x64/include"
    export CFLAGS="-I../libdeflate -I../curl-7.71.1-win64-mingw/include -I../zlib-1.2.5-bin-x64/include"
    export LDFLAGS="-L../libdeflate -L../zlib-1.2.5-bin-x64/lib -L../curl-7.71.1-win64-mingw/lib -ldeflate -lcurl"
    
    #export CPPFLAGS="-I../libdeflate_i686 -I../curl-7.71.1-win32-mingw/include -I../libz-1.2.7-1_mingw32-dev/include"
    #export CFLAGS="-I../libdeflate -I../curl-7.71.1-win32-mingw/include -I../libz-1.2.7-1_mingw32-dev/include"
    #export LDFLAGS="-L../libdeflate_i686 -L../libz-1.2.7-1_mingw32-dev/lib -L../curl-7.71.1-win32-mingw/lib -ldeflate -lcurl"
    
    ./get_htslib.sh
    export CPPFLAGS=
    export CFLAGS=
    export LDFLAGS=
fi

if [[ ! -s libBigWig ]] ; then
    ./get_libBigWig.sh
fi

set -x

#compile a no-curl static version of libBigWig
if [[ $bc == 'megadepth_static1' ]]; then
    pushd libBigWig
    #export CPPFLAGS="-I../curl-7.71.1-win64-mingw/include -I../zlib-1.2.5-bin-x64/include"
    #export CFLAGS="-I../curl-7.71.1-win64-mingw/include -I../zlib-1.2.5-bin-x64/include -g -Wall -O3 -Wsign-compare"
    #export LDFLAGS="-L../zlib-1.2.5-bin-x64/lib -L../curl-7.71.1-win64-mingw/lib"
    export CFLAGS="-I../zlib-1.2.5-bin-x64/include -g -Wall -O3 -Wsign-compare -DNOCURL"
    export LDFLAGS="-L../zlib-1.2.5-bin-x64/lib -lz"
    #export LIBS="-lm"
    make clean
    make CC=x86_64-w64-mingw32-gcc -f Makefile.nocurl lib-static
    #make CC=x86_64-w64-mingw32-gcc -f Makefile.fpic lib-static
    export CPPFLAGS=
    export CFLAGS=
    export LDFLAGS=
    popd
fi

#compile a position indenpendent code static version of libBigWig
#but *with* curl calls present, to be resolved later in the
#dynamic linking of megadepth
if [[ $bc == 'megadepth_statlib' ]]; then
    pushd libBigWig
    make clean
    make -f Makefile.fpic lib-static
    popd
fi

#compile a the original, dynamic version of libBigWig
if [[ $bc == 'megadepth_dynamic' ]]; then
    pushd libBigWig
    make clean
    make -f Makefile.orig lib-shared
    popd
fi

export LD_LIBRARY_PATH=./htslib:./libBigWig:$LD_LIBRARY_PATH

DR=build-release-temp
mkdir -p ${DR}
pushd ${DR}
#build 32bit windows
#cmake -DWIN32=ON -DMINGW=ON -DUSE_SSH=OFF -DCMAKE_RC_COMPILER="$(which x86_64-w64-mingw32-windres)" -DDLLTOOL="$(which x86_64-w64-mingw32-dlltool)" -DCMAKE_FIND_ROOT_PATH=/usr/x86_64-w64-mingw32 -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY -D CMAKE_C_COMPILER=i686-w64-mingw32-gcc -D CMAKE_CXX_COMPILER=i686-w64-mingw32-g++ -DCMAKE_BUILD_TYPE=Release ..
#cmake -DWIN32=ON -DMINGW=ON -DUSE_SSH=OFF -DBUILD_SHARED_LIBS=OFF -DBUILD_CLAR=OFF -DTHREADSAFE=ON -DCMAKE_SYSTEM_NAME=Windows -DDLLTOOL="$(which x86_64-w64-mingw32-dlltool)" -DCMAKE_FIND_ROOT_PATH=/usr/x86_64-w64-mingw32 -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY -D CMAKE_C_COMPILER=x86_64-w64-mingw32-gcc -D CMAKE_CXX_COMPILER=x86_64-w64-mingw32-g++ -DCMAKE_BUILD_TYPE=Release ..
cmake -DCMAKE_BUILD_TYPE=Release ..
make ${bc}
popd
cp ${DR}/${bc} ./
ln -fs ./$bc megadepth
./megadepth --version
rm -rf ${DR}
