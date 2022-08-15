#!/bin/bash

eval `jtcfgstr -target=mist -output=bash -core roc`

if [ ! -e rom.bin ]; then
    ln -s $ROM/rocnrope.rom rom.bin || exit 1
fi

jtsim -mist -sysname roc -load -verilator $*
