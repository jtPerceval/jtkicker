#!/bin/bash

SYSNAME=pinpon

eval `jtcfgstr -target=mist -output=bash -core $SYSNAME`

# PROM_ONLY="-d JTFRAME_DWNLD_PROM_ONLY"
OTHER=
SCENE=
SIMULATOR=-verilator
rm -f sdram*.bin sdram*.hex

for i in $*; do
    case $i in
        -s)
            shift
            SCENE=$1
            OTHER="$OTHER -d NOMAIN -d NOSND -video 2"
            if [ ! -d $SCENE ]; then
                echo Cannot find scene $SCENE
                exit 1
            fi
            ;;
        *)
            OTHER="$OTHER $1";;
    esac
    shift
done

if [ -n "$SCENE" ]; then
    dd if=$SCENE/vram.bin of=vram_lo.bin count=2
    dd if=$SCENE/vram.bin of=vram_hi.bin skip=2 count=2
    cp $SCENE/oram.bin .
fi

jtsim -mist -sysname $SYSNAME $SIMULATOR -load \
    -d JTFRAME_SIM_ROMRQ_NOCHECK \
    -videow 256 -videoh 224 $OTHER
