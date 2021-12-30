#!/bin/bash

AUXTMP=/tmp/$RANDOM$RANDOM
jtcfgstr -target=mist -output=bash -parse ../../hdl/jtsbakt.def > $AUXTMP
source $AUXTMP

#jtsim_sdram
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

# Generic simulation script from JTFRAME
jtsim -mist -sysname sbaskt  \
    $PROM_ONLY -d JTFRAME_SIM_ROMRQ_NOCHECK \
    -videow 256 -videoh 224 \
    $*
