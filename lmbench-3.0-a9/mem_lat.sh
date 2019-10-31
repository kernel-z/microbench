#!/bin/bash
#author : yinchao.zych

if [ ! -n "$1" ] ;then
    echo "input the dies per socket,eg. ./test 2 1, first argu means dies/socket, seconde argu means running times(default is once)"
        exit
else
        echo "the die per sockets is  $1"
        dies=$1
fi
if [ ! -n "$2" ] ;then
        t=1  #running times
else
        t=$2
fi
echo "running times $t" > result_lat.txt

a=`cat /proc/cpuinfo | grep processor | wc -l` #all logical cores
nodes=`numactl --hardware | egrep  "node [0-9]+ cpus"|wc -l` #all nodes
physicals=`lscpu | egrep -i ^socket | awk -F: '{print $2}' | awk '{print $1}'` #all sockets
numaoff=0  #numa defaut off

echo "logical cores: $a, nodes : $nodes, physicals socket: $physicals"

#****************split******************
echo "Die(each node)" >> result_lat.txt
for ((i=0;i<${nodes};i++));
do
	cpus=`numactl --hardware | egrep  "node [0-9]+ cpus"  | egrep "node $i"| awk -F: '{print $2}' | awk '{print $1}'`
	for ((j=0;j<${nodes};j++));
	do
		echo "Node $i->$j" >> result_lat.txt
		for((k=0;k<$t;k++));
		do
            echo "running $i->$j lat,the $k time..."
			numactl -C $cpus -m $j ./lat_mem_rd -P 1 -W 5 -N 5 -t 1024M >> result_lat.txt 2>&1
			sleep 10
		done
	done
done

echo "format result" > result_format_lat.txt
numshow=$(($t*42))
#parse lat by die
#print format  
echo "die to die" >> result_format_lat.txt
j=""
for((i=0;i<${nodes};i++));
do
        j=$j"\t"$i
done
echo -e "\t$j" >> result_format_lat.txt
for((i=0;i<${nodes};i++));
do
	line=""
	for((j=0;j<${nodes};j++));
do
    	
nodebw[$i]=` cat result_lat.txt  | grep -A $numshow "Node $i->$j" | grep "1024.0000"  | awk '{print $2}' | xargs | sed 's/\ /+/g' | bc  `
	        avgbw=`echo ${nodebw[$i]}/$t | bc`
		line=$line"\t"$avgbw
	done
	echo -e $i$line >> result_format_lat.txt
done
#end
