#!/bin/bash

AUXTMP=/tmp/$RANDOM$RANDOM
jtcfgstr -target=mist -output=bash -parse ../../hdl/jtyiear.def |grep _START > $AUXTMP
source $AUXTMP

#jtsim_sdram

export M6809=1

# Generic simulation script from JTFRAME
jtsim -mist -sysname yiear  \
    -d JTFRAME_DWNLD_PROM_ONLY -d JTFRAME_SIM_ROMRQ_NOCHECK \
    -videow 256 -videoh 224 \
    $*
