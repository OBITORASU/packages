#!/bin/bash

pstart="$PWD"
readonly tmp="$PWD/tmp"
mkdir -p "$tmp"

# CLONE PHASE
git clone https://github.com/TES3MP/openmw-tes3mp.git source
pushd source
git checkout -f ad9ee80
git submodule update --init --recursive
popd

git clone https://github.com/TES3MP/CoreScripts server
pushd server
git checkout -f 46698c1
popd

git clone https://github.com/TES3MP/CrabNet.git crabnet
pushd crabnet
git checkout -f 19e6619
popd

git clone https://github.com/Koncord/CallFF.git callff
pushd callff
git checkout -f da94b59
popd

wget https://github.com/zdevito/terra/releases/download/release-2016-03-25/terra-Linux-x86_64-332a506.zip
unzip terra-Linux-x86_64-332a506.zip

# BUILD PHASE
generate_openmw_cfg () {
    tail -n +2 "$1" | sed -e 's!\(data\|resources\)=/usr/local/\(.*\)!\1=\2!g'
    echo "fallback-archive=Morrowind.bsa"
    echo "fallback-archive=Tribunal.bsa"
    echo "fallback-archive=Bloodmoon.bsa"
    echo "content=Morrowind.esm"
    echo "content=Tribunal.esm"
    echo "content=Bloodmoon.esm"
}

pushd crabnet
mkdir -p build
cd build
cmake \
    -DCMAKE_INSTALL_PREFIX="$pfx" \
    -DCRABNET_ENABLE_DLL=OFF \
    -DCRABNET_ENABLE_SAMPLES=OFF \
    -DCMAKE_BUILD_TYPE=Release \
    ..
make -j "$(nproc)"
make install
popd

pushd callff
mkdir -p build
cd build
cmake \
    -DCMAKE_INSTALL_PREFIX="$pfx" \
    ..
make -j "$(nproc)"
popd

export CXXFLAGS="-fpermissive"
export CFLAGS="-fpermissive"
export Terra_ROOT="$pstart/terra-Linux-x86_64-332a506"
export RAKNET_ROOT="$pfx"

pushd "source"
mkdir -p build
cd build
export OSG_DIR="$pfx/lib64"
cmake \
    -DBUILD_LAUNCHER=ON \
    -DDESIRED_QT_VERSION=5 \
    -DBUILD_OPENCS=OFF \
    -DBUILD_WIZARD=ON \
    -DBUILD_MYGUI_PLUGIN=OFF \
    -DCMAKE_PREFIX_PATH="$pfx" \
    -DCMAKE_BUILD_TYPE=MinSizeRel \
    -DRakNet_LIBRARY_DEBUG="$pfx/lib/libRakNetLibStatic.a" \
    -DLuaJit_INCLUDE_DIR="$pfx/usr/local/include/luajit-2.1/" \
    -DLuaJit_LIBRARY="$pfx/usr/local/lib/libluajit-5.1.a" \
    -DCMAKE_CXX_FLAGS="-fpermissive" \
    -DCallFF_INCLUDES="$pstart/callff/include" \
    -DCallFF_LIBRARY="$pstart/callff/build/src/libcallff.a" \
    ..
make -j "$(nproc)"
DESTDIR="$tmp" make install
popd

# COPY PHASE
mkdir -p "$diststart/22320/dist/lib/"
cp -rfv "$pfx/"{lib,lib64}/*.so* "$diststart/22320/dist/lib/"
cp -rfv "$pfx/lib64/"osgPlugins-* "$diststart/22320/dist/lib/"
cp -rfv "$tmp/usr/local/"{etc,share} "$diststart/22320/dist/"
cp -rfv "$tmp/usr/local/bin/"* "$diststart/22320/dist/"

cp "assets/tes3mp-launcher.sh" "$diststart/22320/dist/"
generate_openmw_cfg "$tmp/usr/local/etc/openmw/openmw.cfg" > "$diststart/22320/dist/openmw-template.cfg"
cp "$tmp/usr/local/etc/openmw/settings-default.cfg" "$diststart/22320/dist/"
cp "$tmp/usr/local/etc/openmw/tes3mp-client-default.cfg" "$diststart/22320/dist"
cp "$tmp/usr/local/etc/openmw/tes3mp-server-default.cfg" "$diststart/22320/dist"

cp -rfv server "$diststart/22320/dist"
cp -rfv source/tes3mp-credits.md "$diststart/22320/dist"
cp -rfv assets/version "$diststart/22320/dist/share/games/openmw/resources/version"
