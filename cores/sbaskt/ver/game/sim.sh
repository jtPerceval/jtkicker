#!/bin/bash

eval `jtcfgstr -target=mist -output=bash -core sbakt`

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

jtsim -mist -sysname sbaskt -load \
    $PROM_ONLY -d JTFRAME_SIM_ROMRQ_NOCHECK \
    $*
