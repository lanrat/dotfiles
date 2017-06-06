#!/usr/bin/env bash

NB_CONNECTION=10
PORT_START=1
PORT_END=65535

for (( i=$PORT_START; i<=$PORT_END; i=i+NB_CONNECTION ))
do
    iEnd=$((i + NB_CONNECTION))
    for (( j=$i; j<$iEnd; j++ ))
    do
        #(curl --connect-timeout 1 "portquiz.net:$j" &> /dev/null && echo "> $j") &
        (nc -w 1 -z portquiz.net "$j" &> /dev/null && echo "> $j") &
    done
    wait
done