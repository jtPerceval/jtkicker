#!/bin/bash

eval $(jtframe cfgstr kicker --target=mist --output=bash)

#jtsim_sdram

# Generic simulation script from JTFRAME
jtsim -mist -sysname kicker  \
    -d JTFRAME_DWNLD_PROM_ONLY -d JTFRAME_SIM_ROMRQ_NOCHECK \
    -videow 256 -videoh 224 \
    $*
