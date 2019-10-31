#!/bin/bash
#author : yinchao.zych

if [ ! -n "$1" ] ;then
        echo "input the dies per socket,eg. ./test 2 1, first argu means dies/socket, second argu means running time, third is debug"
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
if [  -n "$3" ] ;then
        DEBUG=1  #running times
else
        DEBUG=0
fi



a=`cat /proc/cpuinfo | grep processor | wc -l` #all logical cores
nodes=`numactl --hardware | egrep  "node [0-9]+ cpus"|wc -l` #all nodes
physicals=`lscpu | egrep -i ^socket | awk -F: '{print $2}' | awk '{print $1}'` #all sockets
numaoff=0  #numa defaut off

k=0 #dies index
j=0 #foreach
cpus=""
mems=""
cpusnum=0
for((i=0;i<${physicals};i++));
do
	for((j=$k;j<$dies;j++))
	do
	        cpu=`numactl --hardware | egrep  "node [0-9]+ cpus"  | egrep "node $j"| awk -F: '{print $2}'| sed 's/^[ \t]*//g' | sed 's/\s\+/,/g'`
	        num=`numactl --hardware | egrep  "node [0-9]+ cpus"  | egrep "node $j"| awk -F: '{print $2}'| wc -w`
       		if [ ! -z "$cpus" ]; then
                	cpus=$cpus","$cpu
			mems=$mems","$j
			cpusnum=$(($cpusnum+$num))
			
        	else
                	cpus=$cpu
			mems=$j
			cpusnum=$(($cpusnum+$num))
        	fi
	done
	k=$j
	dies=$(($dies+$k))
	cpusocket[$i]=$cpus  # each sockets's cpus
	memsocket[$i]=$mems  #each sockets's mem index
	numsocket[$i]=$cpusnum
	if [ $DEBUG == 1 ];then
		echo "socket$i:${cpusocket[$i]}"
		echo "socketmem$i:${memsocket[$i]}"
	fi
	cpus=""
	mems=""
	cpusnum=0
done

#restore dies value
dies=$1


#********************************************************************************
#***************************parse result*****************************************
#********************************************************************************
echo "format result" > result_format_bw.txt
numshow=$(($t*8))
#parse all bw
echo "all bw" >> result_format_bw.txt
nodeallbw=` cat result_stream.txt  | grep -A $numshow "all bw" | grep triad  | grep bandwidth | awk '{print $4}' | xargs | sed 's/\ /+/g' | bc`
echo -e "${nodeallbw}/$t" |bc >> result_format_bw.txt

#parse bw by die
#print format  
echo "die to die" >> result_format_bw.txt
j=""
for((i=0;i<${nodes};i++));
do
        j=$j"\t"$i
done
echo -e "\t$j" >> result_format_bw.txt
for((i=0;i<${nodes};i++));
do
	line=""
	for((j=0;j<${nodes};j++));
	do
    	
       		nodebw[$i]=` cat result_stream.txt  | grep -A $numshow "Node $i->$j" | grep triad  | grep bandwidth | awk '{print $4}' | xargs | sed 's/\ /+/g' | bc  `
	        avgbw=`echo ${nodebw[$i]}/$t | bc`
		line=$line"\t"$avgbw
	done
	echo -e $i$line >> result_format_bw.txt
done

#parse bw by socket
echo "socket to socket" >> result_format_bw.txt
if [ $numaoff == 0 ];then
        j=""    
        for((i=0;i<${physicals};i++));
        do      
                j=$j"\t"$i
        done
        echo -e "\t"$j >> result_format_bw.txt

        for((i=0;i<${physicals};i++));
        do
		line=""
        	for((j=0;j<${physicals};j++));
	        do

       	        	socketbw[$i]=`cat result_stream.txt  | grep -A $numshow "socket $i->$j" | grep triad  | grep bandwidth | awk '{print $4}' | xargs | sed 's/\ /+/g' | bc  `
			avgbw=`echo ${socketbw[$i]}/$t | bc`
			line=$line"\t"$avgbw
		done
		echo -e $i$line >> result_format_bw.txt
        done
fi
#end

