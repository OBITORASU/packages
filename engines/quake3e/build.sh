#!/bin/bash

# CLONE PHASE
git clone https://github.com/ec-/Quake3e.git source
pushd source
git checkout b8ec17b
popd

# BUILD PHASE
pushd "source"
make ARCH=x64_64 -j "$(nproc)"
make install DESTDIR="$diststart/common/dist/"
popd
