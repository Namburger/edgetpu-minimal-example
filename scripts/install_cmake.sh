#!/bin/bash
set -x

sudo apt-get install libssl-dev
wget https://github.com/Kitware/CMake/releases/download/v3.17.0/cmake-3.17.0.tar.gz
tar xvf cmake-3.17.0.tar.gz
rm cmake-3.17.0.tar.gz
cd cmake-3.17.0/
./configure
make
sudo make install
