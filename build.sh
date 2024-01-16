#!/bin/bash

set -o errexit
# set -o pipefail
# set -o nounset
set -o xtrace


echo " --- Installing libgdiplus and tools ..."

tar -zxvf libgdiplus-6.1.tar.gz
cd libgdiplus-6.1/
LIBGDIPLUS=$(pwd)
LIBGDIPLUS_LIB=$(pwd)/lib
sudo apt-get install libgif-dev autoconf libtool automake build-essential gettext libglib2.0-dev libcairo2-dev libtiff-dev libexif-dev
./configure --prefix=$LIBGDIPLUS
make && make install
cd ../

sudo apt install patchelf

VERSION='6.1.0'

NUGET_PREFIX="eashanshan.linux-arm64"
cd $NUGET_PREFIX.System.Drawing 

OUT=$(pwd)/out/usr/local/lib
rm -rf $OUT

mkdir -p $OUT

LIBGDIPLUS_SHARED_OBJ=$LIBGDIPLUS_LIB/libgdiplus.so
LIBGDIPLUS_DEPS=`ldd "$LIBGDIPLUS_SHARED_OBJ" | grep "/" | awk -F' ' '{ print $3 }'`

cp $LIBGDIPLUS_LIB/libgdiplus.so* "$OUT/"

for SHARED_OBJ in $LIBGDIPLUS_DEPS; do
  cp $SHARED_OBJ "$OUT/"
done;

echo " --- :patch: Patching dependencies ..."
for FILE in "$OUT/"*.so*; do
  chmod +w "$FILE"

  SHARED_OBJS=`ldd "$FILE" | grep "/" | awk -F' ' '{ print $3 }'`

  for OBJ in $SHARED_OBJS; do
    BASENAME=`basename "$OBJ"`

    if [ ! -f "$OUT/$BASENAME" ]; then
      echo " --- :ERROR: The shared object file '$OUT/$BASENAME' does not exist in the output folder; referenced from $FILE" 1>&2
      exit 1
    fi

    patchelf --set-rpath \$ORIGIN $FILE
  done;
done

mkdir -p ./bin

dotnet build -c Release -p:Version=${VERSION}

if [[ $* == *--pack* ]]; then
  echo " --- :dotnet: Packing ${NUGET_PREFIX}.${VERSION} ..."
  dotnet pack -c Release -p:Version=${VERSION} -o ./bin/
fi

if [[ $* == *--pack* ]]; then
  echo " --- :dotnet: Packing ${NUGET_PREFIX}.${VERSION} ..."
  dotnet pack -c Release -p:Version=${VERSION} -o ./bin/
fi
