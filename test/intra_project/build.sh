#!/bin/bash

CMAKE=cmake

rm -rf build/* &&
rm -rf install/* &&
cd "build" && \
${CMAKE} "$@" -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=../install -DBUILD_DOCS=ON .. && \
make install
