#!/bin/sh
./downloadassets.sh
dos2unix comptime.sh
make -C src/ SWITCH=1 clean
make -j$((`nproc`+1)) -C src/ SWITCH=1