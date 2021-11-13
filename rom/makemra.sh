#!/bin/bash

cd $JTUTIL/src
make || exit $?
cd -
echo "------------"

mkdir -p mra/_alt

# AUXTMP=/tmp/$RANDOM$RANDOM
# DEF=$CORES/kicker/hdl/jtkicker.def
# jtcfgstr -target=mist -output=bash -def $DEF|grep _START > $AUXTMP
# source $AUXTMP

# System 16B
# mame2mra -def $CORES/s16b/hdl/jts16b.def -toml s16b.toml -outdir mra $*
mame2mra -toml kicker.toml -outdir mra $*

sshpass -p 1 scp -r mra/* root@MiSTer.home:/media/fat/_JT
