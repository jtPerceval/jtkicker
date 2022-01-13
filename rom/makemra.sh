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

for i in kicker yiear sbaskt mikie; do
    mame2mra -toml $i.toml -outdir mra $*
done

sshpass -p 1 scp -r mra/* root@MiSTer.home:/media/fat/_JT
