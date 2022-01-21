#!/bin/bash

SYSNAME=mikie

eval `jtcfgstr -target=mist -output=bash -core $SYSNAME`

if [ -e vram.bin ]; then
    cat vram.bin | drop1    > vram_hi.bin
    cat vram.bin | drop1 -l > vram_lo.bin
fi

# PROM_ONLY="-d JTFRAME_DWNLD_PROM_ONLY"
OTHER=
SCENE=
SIMULATOR=-verilator

for i in $*; do
    case $i in
        -s)
            shift
            SCENE=$1
            OTHER="$OTHER -d NOMAIN -d NOSND -video 2"
            ;;
        *)
            OTHER="$OTHER $1";;
    esac
    shift
done

if [ -n "$SCENE" ]; then
    cp $SCENE/vram_{lo,hi}.bin .
    go run obj2sim.go $SCENE/obj.bin || exit $?
    # pal_sel.hex must be one line, no \n character.
    OTHER="$OTHER -d PALSEL="`cat $SCENE/pal_sel.hex`
fi

export M6809=1

jtsim -mist -sysname $SYSNAME -load $SIMULATOR \
    -d JTFRAME_SIM_ROMRQ_NOCHECK \
    -videow 256 -videoh 224 $OTHER
