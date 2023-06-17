#!/bin/bash
BASE_PATH=`pwd`

mkdir -p target

echo "0. Fetching LK2nd fork..."
if [ ! -d "bootloader" ]
then
    echo "--> Fetching forked lk2nd tree..."
    git clone -b quectel-eg25-timer https://github.com/Biktorgj/lk2nd.git bootloader
else
    echo "--> Updating lk2nd..."
    cd lk2nd && \
    git pull && \
    cd $BASE_PATH
fi

echo "0. Fetching 3.18.140 kernel..."
if [ ! -d "kernel" ]
then
    echo "--> Fetching kernel tree..."
    git clone -b linux-3.18.140 https://github.com/the-modem-distro/quectel_eg25_kernel.git linux-3.18.140
else
    echo "--> Updating kernel..."
    cd linux-3.18.140 && \
    git pull && \
    cd $BASE_PATH
fi

cd $BASE_PATH/tools/src/dtbtool && make && mv dtbtool $BASE_PATH/tools/
cd $BASE_PATH/tools/src/mkbootimg && make && mv mkbootimg $BASE_PATH/tools