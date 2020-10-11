#!/bin/bash

CMAKE=cmake

build () {
  (
    cd "$1" && \
    shift && \
    rm -rf build/* && \
    rm -rf install/* && \
    cd build && \
    ${CMAKE} "$@" -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=../install -DBUILD_DOCS=ON .. && \
    make install
  )
}

build project_a "$@" && \
build project_b "$@" -DCMAKE_PREFIX_PATH=$(realpath project_a/install/share/cmake/project_a)
