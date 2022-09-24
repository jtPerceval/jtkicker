#!/bin/bash

eval $(jtframe cfgstr kicker --target=mist --output=bash)

#jtsim_sdram
if [ -e vram.bin ]; then
    cat vram.bin | drop1    > vram_hi.bin
    cat vram.bin | drop1 -l > vram_lo.bin
fi

PROM_ONLY="-d JTFRAME_DWNLD_PROM_ONLY"

for i in $*; do
    case $i in
        -load) PROM_ONLY=;;
    esac
done

# Generic simulation script from JTFRAME
jtsim -mist -sysname yiear  \
    $PROM_ONLY -d JTFRAME_SIM_ROMRQ_NOCHECK \
    -videow 256 -videoh 224 \
    $*
