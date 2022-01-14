#!/bin/bash

SYSNAME=mikie

eval `jtcfgstr -target=mist -output=bash -core $SYSNAME`

if [ -e vram.bin ]; then
    cat vram.bin | drop1    > vram_hi.bin
    cat vram.bin | drop1 -l > vram_lo.bin
fi

PROM_ONLY="-d JTFRAME_DWNLD_PROM_ONLY"
EXTRA=

for i in $*; do
    case $i in
        -load)
            PROM_ONLY=
            EXTRA="-d NOMAIN -d NOSND"
            ;;
    esac
done

export M6809=1

jtsim -mist -sysname $SYSNAME -load \
    $PROM_ONLY -d JTFRAME_SIM_ROMRQ_NOCHECK \
    -videow 256 -videoh 224 \
    $*
