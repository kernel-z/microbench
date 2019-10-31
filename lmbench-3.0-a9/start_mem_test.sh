#!/bin/bash
#first argu is dies/socket, second argu is running times.
if [ ! -n "$2" ] ;then
	echo "please input the dies/socket,and the running times"
	echo "input the dies per socket,eg. ./test 2 1, first argu means dies/socket, second argu means running time, third is debug"
	exit
fi

make
path=`find -name stream`
cp mem_lat.sh ${path%/*}/
cp mem_bw.sh ${path%/*}/
cd ${path%/*}

sh mem_lat.sh $1 $2
sh mem_bw.sh $1 $2
