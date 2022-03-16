#!/bin/bash

SYSNAME=roadf

eval `jtcfgstr -target=mist -output=bash -core $SYSNAME`

# PROM_ONLY="-d JTFRAME_DWNLD_PROM_ONLY"
OTHER=
SCENE=
# SIMULATOR=-verilator

for i in $*; do
    case $i in
        -g)
            shift
            if [ ! -e $ROM/$1.rom ]; then
                echo Cannot find $ROM/$1.rom
                exit 1
            fi
            ln -sf $ROM/$1.rom rom.bin
            ;;
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

# if [ -n "$SCENE" ]; then
#     cp $SCENE/vram_{lo,hi}.bin .
#     go run obj2sim.go $SCENE/obj.bin || exit $?
#     # pal_sel.hex must be one line, no \n character.
#     OTHER="$OTHER -d PALSEL="`cat $SCENE/pal_sel.hex`
# fi

export M6809=1

jtsim -mist -sysname $SYSNAME $SIMULATOR -load \
    -d JTFRAME_SIM_ROMRQ_NOCHECK \
    -videow 256 -videoh 224 $OTHER
